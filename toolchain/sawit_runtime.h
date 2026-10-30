#ifndef SAWIT_RUNTIME_H
#define SAWIT_RUNTIME_H

#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

static int sawit_stdout_bungkam = 0;
static int sawit_stderr_bungkam = 0;

static inline void sawit_bungkam(FILE *stream) {
    if (stream == stdout) sawit_stdout_bungkam = 1;
    if (stream == stderr) sawit_stderr_bungkam = 1;
}

static inline void sawit_buka_suara(FILE *stream) {
    if (stream == stdout) sawit_stdout_bungkam = 0;
    if (stream == stderr) sawit_stderr_bungkam = 0;
}

static inline void sawit_buzzer(const char *format, ...) {
    if (sawit_stdout_bungkam) return;
    va_list args;
    va_start(args, format);
    vfprintf(stdout, format, args);
    va_end(args);
    fflush(stdout);
}

static inline void sawit_demo_masyarakat(const char *format, ...) {
    if (sawit_stderr_bungkam) return;
    va_list args;
    va_start(args, format);
    fputs("[DEMO MASYARAKAT] ", stderr);
    vfprintf(stderr, format, args);
    fputc('\n', stderr);
    va_end(args);
    fflush(stderr);
}

static inline void sawit_bersihkan_layar(void) {
#ifdef _WIN32
    (void)system("cls");
#else
    fputs("\033[2J\033[H", stdout);
    fflush(stdout);
#endif
}

#define sawit_pajak(value, percent) \
    ((value) -= ((value) * (percent)) / 100)

/* MBG credits funds; cair disburses only what is currently available. */
static long long sawit_anggaran = 0;

static inline long long sawit_mbg(long long amount) {
    if (amount > 0) sawit_anggaran += amount;
    return amount;
}

static inline long long sawit_cair(long long amount) {
    if (amount <= 0 || amount > sawit_anggaran) return 0;
    sawit_anggaran -= amount;
    return amount;
}

/* Tracked heap allocations: beli allocates, jual releases and unregisters. */
typedef struct SawitAllocation {
    void *pointer;
    size_t bytes;
    struct SawitAllocation *next;
} SawitAllocation;

static SawitAllocation *sawit_allocations = NULL;

static inline void *sawit_beli(size_t bytes) {
    if (bytes == 0) bytes = 1;
    void *pointer = malloc(bytes);
    if (!pointer) return NULL;
    SawitAllocation *record = (SawitAllocation *)malloc(sizeof(SawitAllocation));
    if (!record) {
        free(pointer);
        return NULL;
    }
    record->pointer = pointer;
    record->bytes = bytes;
    record->next = sawit_allocations;
    sawit_allocations = record;
    return pointer;
}

static inline void sawit_jual(void *pointer) {
    if (!pointer) return;
    SawitAllocation **cursor = &sawit_allocations;
    while (*cursor) {
        if ((*cursor)->pointer == pointer) {
            SawitAllocation *record = *cursor;
            *cursor = record->next;
            free(record);
            free(pointer);
            return;
        }
        cursor = &(*cursor)->next;
    }
    /* Pointer bukan hasil beli(): abaikan. Ini mencegah double-free
       (jual dua kali pada pointer yang sama) dan mencegah free() pada
       pointer yang tidak dimiliki allocator (mis. variabel stack). */
}

#define sawit_nyawit(function) ((function)())

#endif
