#ifndef MUTEX_ATTRIBUTES_INCLUDED
#define MUTEX_ATTRIBUTES_INCLUDED
#ifdef  __cplusplus
extern "C" {
#endif


/* From http://clang.llvm.org/docs/ThreadSafetyAnalysis.html */

/* Enable thread safety attributes only with clang.
   The attributes can be safely erased when compiling with other compilers.

   THREAD_ANNOTATION_CFUNCTION__ added in light of https://bugs.llvm.org/show_bug.cgi?id=33755
   as a necessary evil to declare C functions that lock a resource.
*/

#if defined(__clang__)
#define THREAD_ANNOTATION_ATTRIBUTE__(...)  __attribute__((__VA_ARGS__))
#define THREAD_ANNOTATION_CFUNCTION__(...)  __attribute__((no_thread_safety_analysis,__VA_ARGS__))
#else
#define THREAD_ANNOTATION_ATTRIBUTE__(...)   // no-op
#define THREAD_ANNOTATION_CFUNCTION__(...)
#endif

#define CAPABILITY(x) \
  THREAD_ANNOTATION_ATTRIBUTE__(capability(x))

#define SCOPED_CAPABILITY \
  THREAD_ANNOTATION_ATTRIBUTE__(scoped_lockable)

#define GUARDED_BY(x) \
  THREAD_ANNOTATION_ATTRIBUTE__(guarded_by(x))

#define PT_GUARDED_BY(x) \
  THREAD_ANNOTATION_ATTRIBUTE__(pt_guarded_by(x))

#define ACQUIRED_BEFORE(...) \
  THREAD_ANNOTATION_ATTRIBUTE__(acquired_before(__VA_ARGS__))

#define ACQUIRED_AFTER(...) \
  THREAD_ANNOTATION_ATTRIBUTE__(acquired_after(__VA_ARGS__))

#define REQUIRES(...) \
  THREAD_ANNOTATION_ATTRIBUTE__(requires_capability(__VA_ARGS__))

#define REQUIRES_SHARED(...) \
  THREAD_ANNOTATION_ATTRIBUTE__(requires_shared_capability(__VA_ARGS__))

#define ACQUIRE_CFUNCTION(...) \
  THREAD_ANNOTATION_CFUNCTION__(acquire_capability(__VA_ARGS__))

#define ACQUIRE(...) \
  THREAD_ANNOTATION_ATTRIBUTE__(acquire_capability(__VA_ARGS__))

#define ACQUIRE_SHARED_CFUNCTION(...) \
  THREAD_ANNOTATION_CFUNCTION__(acquire_shared_capability(__VA_ARGS__))

#define ACQUIRE_SHARED(...) \
  THREAD_ANNOTATION_ATTRIBUTE__(acquire_shared_capability(__VA_ARGS__))

#define RELEASE_CFUNCTION(...) \
  THREAD_ANNOTATION_CFUNCTION__(no_thread_safety_analysis,release_capability(__VA_ARGS__))

#define RELEASE(...) \
  THREAD_ANNOTATION_ATTRIBUTE__(release_capability(__VA_ARGS__))

#define RELEASE_SHARED_CFUNCTION(...) \
  THREAD_ANNOTATION_CFUNCTION__(release_shared_capability(__VA_ARGS__))

#define RELEASE_SHARED(...) \
  THREAD_ANNOTATION_ATTRIBUTE__(release_shared_capability(__VA_ARGS__))

#define TRY_ACQUIRE_CFUNCTION(...) \
  THREAD_ANNOTATION_CFUNCTION__(try_acquire_capability(__VA_ARGS__))

#define TRY_ACQUIRE(...) \
  THREAD_ANNOTATION_ATTRIBUTE__(try_acquire_capability(__VA_ARGS__))

#define TRY_ACQUIRE_SHARED_CFUNCTION(...) \
  THREAD_ANNOTATION_CFUNCTION__(try_acquire_shared_capability(__VA_ARGS__))

#define TRY_ACQUIRE_SHARED(...) \
  THREAD_ANNOTATION_ATTRIBUTE__(try_acquire_shared_capability(__VA_ARGS__))

#define EXCLUDES(...) \
  THREAD_ANNOTATION_ATTRIBUTE__(locks_excluded(__VA_ARGS__))

#define ASSERT_CAPABILITY(x) \
  THREAD_ANNOTATION_ATTRIBUTE__(assert_capability(x))

#define ASSERT_SHARED_CAPABILITY(x) \
  THREAD_ANNOTATION_ATTRIBUTE__(assert_shared_capability(x))

#define RETURN_CAPABILITY(x) \
  THREAD_ANNOTATION_ATTRIBUTE__(lock_returned(x))

#define NO_THREAD_SAFETY_ANALYSIS \
  THREAD_ANNOTATION_ATTRIBUTE__(no_thread_safety_analysis)


#ifdef  __cplusplus
}
#endif

#endif /* MUTEX_ATTRIBUTES_INCLUDED */
