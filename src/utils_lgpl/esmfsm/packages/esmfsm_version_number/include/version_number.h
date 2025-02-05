#define COMPANY       "Deltares"
#define PROGRAM       "ESMFSM"         /* This name will be used to represent to the user */
#define SHORT_PROGRAM "ESMFSM"         /* This name will be used in filename constructions */
#define MOD_NAME       ESMFSM          /* Will be added to the function names */
#if HAVE_CONFIG_H
#   define F90_MOD_NAME   FC_FUNC(esmfsm, ESMFSM)
#else
#   define F90_MOD_NAME   MOD_NAME
#endif
#define PROG_VERSION  "4.06.00"    /* Version must include at least two dots, starting with a real number followed by a dot */
#define FILE_VERSION  "undefined"                        /* Needed for the file header */
#define BUILD_NUMBER  "000000"
