//
//  OrzClang.m
//  OrzHook
//
//  Created by wangzhizhou on 2021/9/25.
//

// 主工程全源码编译，用于获取全部符号
// Clang插桩文档参考: https://clang.llvm.org/docs/SanitizerCoverage.html#tracing-pcs-with-guards
// 项目的OTHER_CFLAGS中添加: -fsanitize-coverage=trace-pc-guard 加这个标记遇到循环无法解决，需要改成: -fsanitize-coverage=func,trace-pc-guard

#ifdef DEBUG

#import "OrzOrderFile.h"
#import <dlfcn.h>
#import <libkern/OSAtomic.h>
#import <set>
#import <vector>

//原子队列
static OSQueueHead symboList = OS_ATOMIC_QUEUE_INIT;
//定义符号结构体
typedef struct{
    void * pc;
    void * next;
}SymbolNode;

BOOL isStopRecordOrderFileSymbols = NO;

static long long symbolTotalCount = 0;
extern "C" NSArray<NSString *>* getOrderFileSymbols(void) {
    NSLog(@"OrzOrderFile: 共收集%@个符号(处理前)", @(symbolTotalCount));
    NSMutableArray<NSString *> *symbols = [NSMutableArray array];

    NSDate *preStartDate = [NSDate date];
    
    std::set<void *> s;
    std::vector<void *> v;
    while(true) {
        SymbolNode * node = (SymbolNode *)OSAtomicDequeue(&symboList, offsetof(SymbolNode, next));
        if (node == NULL) {
            NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:preStartDate];
            NSLog(@"OrzOrderFile: 预处理耗时 = %@s(去重后：%lu, 总计：%lu)", @(duration), s.size(), v.size());
            break;
        }
        v.push_back(node->pc);
        s.insert(node->pc);
        free(node);
    }
    
    long long currentProcessSymbolIndex = 0;
    long long estimateMaxParseSymbolCount = 1E4;
    
    NSDate *startDate = [NSDate date];
    for(auto it = v.rbegin(); it != v.rend(); it++) {
        currentProcessSymbolIndex++;
        if(currentProcessSymbolIndex == estimateMaxParseSymbolCount) {
            NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:startDate];
            NSLog(@"OrzOrderFile: 处理%@个符号耗时 = %@s, 预估全部处理完成，最长需要 = %@s", @(estimateMaxParseSymbolCount), @(duration), @(v.size() / (double)currentProcessSymbolIndex * duration));
        }
        
        if(!s.count(*it)) {
            continue;
        }
        s.erase(*it);
        
        // 符号解析
        Dl_info info;
        dladdr(*it, &info);
        NSString *symbol = [NSString stringWithUTF8String:info.dli_sname];
        BOOL isObjc = [symbol hasPrefix:@"-["] || [symbol hasPrefix:@"+["];
        symbol = isObjc ? symbol : [@"_" stringByAppendingString:symbol];
        if (symbol.length > 0) {
            [symbols addObject:symbol];
        }
    }
    
    NSLog(@"OrzOrderFile: 共计%@个符号(处理后), 总耗时: %@s", @(symbols.count), @([[NSDate date] timeIntervalSinceDate:preStartDate]));
    return symbols.copy;
}

#pragma mark - Clang 插桩代码

extern "C" void __sanitizer_cov_trace_pc_guard_init(uint32_t *start,
                                                    uint32_t *stop) {
    static uint32_t N;  // Counter for the guards.
    if (start == stop || *start) return;  // Initialize only once.
    // NSLog(@"INIT: %p %p\n", start, stop);
    for (uint32_t *x = start; x < stop; x++)
        *x = ++N;  // Guards should start from 1.
}

extern "C" void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
    if (!*guard) return;  // Duplicate the guard check.
    
    static BOOL isSetup = NO;
    if(!isSetup) {
        isSetup = YES;
        [OrzOrderFile setup];
    }
    
    if (isStopRecordOrderFileSymbols) {
        return;
    }
    
    void *PC = __builtin_return_address(0);
    SymbolNode * node = (SymbolNode *)malloc(sizeof(SymbolNode));
    *node = (SymbolNode){PC,NULL};
    OSAtomicEnqueue(&symboList, node, offsetof(SymbolNode, next));
    symbolTotalCount++;
}
#endif
