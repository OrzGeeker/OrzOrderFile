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

//原子队列
static OSQueueHead symboList = OS_ATOMIC_QUEUE_INIT;
//定义符号结构体
typedef struct{
    void * pc;
    void * next;
}SymbolNode;

BOOL isStopRecordOrderFileSymbols = NO;

static long long symbolTotalCount = 0;
extern "C" NSArray<NSString *>* getOrderFileSymbols() {
    NSLog(@"OrzOrderFile: 共计%@个符号(处理前)", @(symbolTotalCount));
    NSMutableArray<NSString *> *symbols = [NSMutableArray array];
    static long long currentProcessSymbolIndex = 0;
    while(true) {
        currentProcessSymbolIndex++;
        // offsetof 找到结构体某个属性的相对偏移量
        SymbolNode * node = (SymbolNode *)OSAtomicDequeue(&symboList, offsetof(SymbolNode, next));
        if (node == NULL) break;
        
        Dl_info info;
        dladdr(node->pc, &info);
        
        NSString *symbol = [NSString stringWithUTF8String:info.dli_sname];
        if (symbol.length > 0 && ![symbols containsObject:symbol]) {
            [symbols insertObject:symbol atIndex:0];
        }
    }
    NSLog(@"OrzOrderFile: 共计%@个符号(处理后)", @(symbols.count));
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
