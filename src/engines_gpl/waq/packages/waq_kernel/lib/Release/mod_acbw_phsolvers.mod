	  K  S   k820309    �          15.0         �qW                                                                                                           
       C:\Users\ccchart\Desktop\20160119_tidal_turbines-new\src\engines_gpl\waq\packages\waq_kernel\src\waq_process\solvesaphe\mod_acbw_phsolvers.F90 MOD_ACBW_PHSOLVERS          AHINI_FOR_ACBW SOLVE_AC                                                
                                                     KIND                                                                                                                                
        
         :�0�yE>        1.E-8                                                                2               50                                                                2               50                                                                2               50                                                                2               50                                         	                       2               50      @                                 
              @                                               @                                               @                                               @                                         %     @                                                  
   #EQUATION_ACBW%PRESENT    #P_ALKTOT    #P_H    #P_DICTOT    #P_BORTOT    #P_DERIVEQN                                               PRESENT       
                                      
        
                                      
        
                                      
        
                                      
        F @                                   
   #     @                                                     #ACBW_HINFSUP%SQRT    #P_ALKCBW    #P_DICTOT    #P_BORTOT    #P_HINF    #P_HSUP                                               SQRT       
                                      
        
                                      
        
                                      
        D                                     
         D                                     
   %     @                                                   
   #SOLVE_ACBW_POLY%EXP    #SOLVE_ACBW_POLY%ABS    #SOLVE_ACBW_POLY%HUGE     #SOLVE_ACBW_POLY%MIN !   #SOLVE_ACBW_POLY%MAX "   #SOLVE_ACBW_POLY%SQRT #   #SOLVE_ACBW_POLY%PRESENT $   #P_ALKCBW %   #P_DICTOT &   #P_BORTOT '   #P_HINI (   #P_VAL )                                              EXP                                            ABS                                             HUGE                                       !     MIN                                       "     MAX                                       #     SQRT                                       $     PRESENT       
  @                              %     
        
  @                              &     
        
  @                              '     
        
 @                              (     
        F @                              )     
   %     @                                *                   
   #SOLVE_ACBW_POLYFAST%ABS +   #SOLVE_ACBW_POLYFAST%HUGE ,   #SOLVE_ACBW_POLYFAST%PRESENT -   #P_ALKCBW .   #P_DICTOT /   #P_BORTOT 0   #P_HINI 1   #P_VAL 2                                         +     ABS                                       ,     HUGE                                       -     PRESENT       
  @                              .     
        
  @                              /     
        
  @                              0     
        
 @                              1     
        F @                              2     
   %     @                                3                   
   #SOLVE_ACBW_GENERAL%EXP 4   #SOLVE_ACBW_GENERAL%ABS 5   #SOLVE_ACBW_GENERAL%HUGE 6   #SOLVE_ACBW_GENERAL%MIN 7   #SOLVE_ACBW_GENERAL%MAX 8   #SOLVE_ACBW_GENERAL%SQRT 9   #SOLVE_ACBW_GENERAL%PRESENT :   #P_ALKCBW ;   #P_DICTOT <   #P_BORTOT =   #P_HINI >   #P_VAL ?                                         4     EXP                                       5     ABS                                       6     HUGE                                       7     MIN                                       8     MAX                                       9     SQRT                                       :     PRESENT       
  @                              ;     
        
  @                              <     
        
  @                              =     
        
 @                              >     
        F @                              ?     
   %     @                                @                   
   #SOLVE_ACBW_ICACFP%ABS A   #SOLVE_ACBW_ICACFP%HUGE B   #SOLVE_ACBW_ICACFP%PRESENT C   #P_ALKCBW D   #P_DICTOT E   #P_BORTOT F   #P_HINI G   #P_VAL H                                         A     ABS                                       B     HUGE                                       C     PRESENT       
  @                              D     
        
  @                              E     
        
  @                              F     
        
 @                              G     
        F @                              H     
   %     @                                I                   
   #SOLVE_ACBW_BACASTOW%ABS J   #SOLVE_ACBW_BACASTOW%HUGE K   #SOLVE_ACBW_BACASTOW%PRESENT L   #P_ALKCBW M   #P_DICTOT N   #P_BORTOT O   #P_HINI P   #P_VAL Q                                         J     ABS                                       K     HUGE                                       L     PRESENT       
  @                              M     
        
  @                              N     
        
  @                              O     
        
 @                              P     
        F @                              Q     
      �   �      fn#fn (   J  $   b   uapp(MOD_ACBW_PHSOLVERS    n  <   J   MOD_PRECISION #   �  9       KIND+MOD_PRECISION !   �  \       WP+MOD_PRECISION "   ?  a       PP_RDEL_AH_TARGET &   �  ^       JP_MAXNITER_ACBW_POLY *   �  ^       JP_MAXNITER_ACBW_POLYFAST )   \  ^       JP_MAXNITER_ACBW_GENERAL (   �  ^       JP_MAXNITER_ACBW_ICACFP *     ^       JP_MAXNITER_ACBW_BACASTOW     v  8       NITER_ACBW_POLY $   �  8       NITER_ACBW_POLYFAST #   �  8       NITER_ACBW_GENERAL "     8       NITER_ACBW_ICACFP $   V  8       NITER_ACBW_BACASTOW    �  �       EQUATION_ACBW &   4  <      EQUATION_ACBW%PRESENT '   p  8   a   EQUATION_ACBW%P_ALKTOT "   �  8   a   EQUATION_ACBW%P_H '   �  8   a   EQUATION_ACBW%P_DICTOT '     8   a   EQUATION_ACBW%P_BORTOT )   P  8   a   EQUATION_ACBW%P_DERIVEQN    �  �       ACBW_HINFSUP "   %  9      ACBW_HINFSUP%SQRT &   ^  8   a   ACBW_HINFSUP%P_ALKCBW &   �  8   a   ACBW_HINFSUP%P_DICTOT &   �  8   a   ACBW_HINFSUP%P_BORTOT $   	  8   a   ACBW_HINFSUP%P_HINF $   >	  8   a   ACBW_HINFSUP%P_HSUP     v	  >      SOLVE_ACBW_POLY $   �
  8      SOLVE_ACBW_POLY%EXP $   �
  8      SOLVE_ACBW_POLY%ABS %   $  9      SOLVE_ACBW_POLY%HUGE $   ]  8      SOLVE_ACBW_POLY%MIN $   �  8      SOLVE_ACBW_POLY%MAX %   �  9      SOLVE_ACBW_POLY%SQRT (     <      SOLVE_ACBW_POLY%PRESENT )   B  8   a   SOLVE_ACBW_POLY%P_ALKCBW )   z  8   a   SOLVE_ACBW_POLY%P_DICTOT )   �  8   a   SOLVE_ACBW_POLY%P_BORTOT '   �  8   a   SOLVE_ACBW_POLY%P_HINI &   "  8   a   SOLVE_ACBW_POLY%P_VAL $   Z  �       SOLVE_ACBW_POLYFAST (   ?  8      SOLVE_ACBW_POLYFAST%ABS )   w  9      SOLVE_ACBW_POLYFAST%HUGE ,   �  <      SOLVE_ACBW_POLYFAST%PRESENT -   �  8   a   SOLVE_ACBW_POLYFAST%P_ALKCBW -   $  8   a   SOLVE_ACBW_POLYFAST%P_DICTOT -   \  8   a   SOLVE_ACBW_POLYFAST%P_BORTOT +   �  8   a   SOLVE_ACBW_POLYFAST%P_HINI *   �  8   a   SOLVE_ACBW_POLYFAST%P_VAL #     S      SOLVE_ACBW_GENERAL '   W  8      SOLVE_ACBW_GENERAL%EXP '   �  8      SOLVE_ACBW_GENERAL%ABS (   �  9      SOLVE_ACBW_GENERAL%HUGE '      8      SOLVE_ACBW_GENERAL%MIN '   8  8      SOLVE_ACBW_GENERAL%MAX (   p  9      SOLVE_ACBW_GENERAL%SQRT +   �  <      SOLVE_ACBW_GENERAL%PRESENT ,   �  8   a   SOLVE_ACBW_GENERAL%P_ALKCBW ,     8   a   SOLVE_ACBW_GENERAL%P_DICTOT ,   U  8   a   SOLVE_ACBW_GENERAL%P_BORTOT *   �  8   a   SOLVE_ACBW_GENERAL%P_HINI )   �  8   a   SOLVE_ACBW_GENERAL%P_VAL "   �  �       SOLVE_ACBW_ICACFP &   �  8      SOLVE_ACBW_ICACFP%ABS '     9      SOLVE_ACBW_ICACFP%HUGE *   M  <      SOLVE_ACBW_ICACFP%PRESENT +   �  8   a   SOLVE_ACBW_ICACFP%P_ALKCBW +   �  8   a   SOLVE_ACBW_ICACFP%P_DICTOT +   �  8   a   SOLVE_ACBW_ICACFP%P_BORTOT )   1  8   a   SOLVE_ACBW_ICACFP%P_HINI (   i  8   a   SOLVE_ACBW_ICACFP%P_VAL $   �  �       SOLVE_ACBW_BACASTOW (   �  8      SOLVE_ACBW_BACASTOW%ABS )   �  9      SOLVE_ACBW_BACASTOW%HUGE ,   �  <      SOLVE_ACBW_BACASTOW%PRESENT -   3  8   a   SOLVE_ACBW_BACASTOW%P_ALKCBW -   k  8   a   SOLVE_ACBW_BACASTOW%P_DICTOT -   �  8   a   SOLVE_ACBW_BACASTOW%P_BORTOT +   �  8   a   SOLVE_ACBW_BACASTOW%P_HINI *     8   a   SOLVE_ACBW_BACASTOW%P_VAL 