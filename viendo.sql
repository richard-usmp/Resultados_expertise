IF @ACCION_CARGA = 'RESULTADO_EXPERTISE'
        BEGIN
            SELECT ID_CARGA,
                   FECHA,
                   MATRICULA,
                   ROL,
                   MATRICULA_CALIFICADOR,
                   ROL_CALIFICADOR,
                   CHAPTER,
                   CAPACIDAD,
                   N_NIVEL,
				   FLAG_CONOCIMIENTO,
				   COMENTARIO
			INTO #TMP_STAGE_RESULTADO_CAPACIDAD
			FROM BCP_GDH_PA_STAGE.PDIGITAL.RESULTADO_CAPACIDAD
			WHERE ID_CARGA = @ID_CARGA;

            SELECT ID_CARGA,
                   FECHA,
				   MATRICULA,
                   ROL,
                   MATRICULA_CALIFICADOR,
                   ROL_CALIFICADOR,
                   CHAPTER,
                   COMPORTAMIENTO,
                   N_NIVEL
			INTO #TMP_STAGE_RESULTADO_COMPORTAMIENTO
			FROM BCP_GDH_PA_STAGE.PDIGITAL.RESULTADO_COMPORTAMIENTO
			WHERE ID_CARGA = @ID_CARGA;

            SELECT *
            INTO #TMP_STAGE_NIVEL
            FROM
            (
                SELECT 0 AS N_NIVEL, 'No evidenciado' AS DESCRIPCION UNION ALL
                SELECT 1 AS N_NIVEL, 'Novato' AS DESCRIPCION UNION ALL
                SELECT 2 AS N_NIVEL, 'Principiante avanzado' AS DESCRIPCION UNION ALL
                SELECT 3 AS N_NIVEL, 'Competente' AS DESCRIPCION UNION ALL
                SELECT 4 AS N_NIVEL, 'Proficiente' AS DESCRIPCION UNION ALL
                SELECT 5 AS N_NIVEL, 'Master' AS DESCRIPCION
            ) T

            DECLARE @FECHA_RESULTADO INT =  (SELECT DISTINCT FECHA FROM #TMP_STAGE_RESULTADO_CAPACIDAD);
            DELETE FROM BCP_GDH_PA_DW.PDIGITAL.F_RESULTADO_CAPACIDAD WHERE FK_FECHA=@FECHA_RESULTADO;
            DELETE FROM BCP_GDH_PA_DW.PDIGITAL.F_RESULTADO_COMPORTAMIENTO WHERE FK_FECHA=@FECHA_RESULTADO;
            DELETE FROM BCP_GDH_PA_DW.PDIGITAL.F_RESULTADO_EXPERTISE WHERE FK_FECHA=@FECHA_RESULTADO;
            
            -- INSERTANDO RESULTADO CAPACIDAD
            INSERT INTO BCP_GDH_PA_DW.PDIGITAL.F_RESULTADO_CAPACIDAD(FK_FECHA,MATRICULA,ROL,MATRICULA_CALIFICADOR,ROL_CALIFICADOR,FK_CHAPTER,FK_CAPACIDAD,N_NIVEL,NIVEL,FLAG_CONOCIMIENTO,COMENTARIO)
            SELECT SC.FECHA,
                   SC.MATRICULA,
                   SC.ROL,
                   SC.MATRICULA_CALIFICADOR,
                   SC.ROL_CALIFICADOR,
                   DC.PK_CHAPTER,
                   DP.PK_CAPACIDAD,
                   SC.N_NIVEL,
                   SN.DESCRIPCION,
				   SC.FLAG_CONOCIMIENTO,
				   SC.COMENTARIO
            FROM #TMP_STAGE_RESULTADO_CAPACIDAD SC
                LEFT JOIN BCP_GDH_PA_DW.PDIGITAL.D_CHAPTER DC ON SC.CHAPTER=DC.DESCRIPCION
                LEFT JOIN BCP_GDH_PA_DW.PDIGITAL.D_CAPACIDAD DP ON SC.CAPACIDAD=DP.DESCRIPCION
                LEFT JOIN #TMP_STAGE_NIVEL SN ON SC.N_NIVEL=SN.N_NIVEL
            
            -- INSERTANDO RESULTADO CAPACIDAD
            SELECT DP.DESCRIPCION AS CHAPTER,
                FCC.ROL,
                DC.DESCRIPCION AS CAPACIDAD,
                FCC.SUBCATEGORIA_CAPACIDAD AS TIPO_CAPACIDAD
            INTO #TMP_TIPO_CAPACIDAD
            FROM BCP_GDH_PA_DW.PDIGITAL.F_CAPACIDAD_CATEGORIA FCC
                LEFT JOIN BCP_GDH_PA_DW.PDIGITAL.D_CHAPTER DP ON FCC.FK_CHAPTER=DP.PK_CHAPTER
                LEFT JOIN BCP_GDH_PA_DW.PDIGITAL.D_CAPACIDAD DC ON FCC.FK_CAPACIDAD=DC.PK_CAPACIDAD
            WHERE FK_FECHA_FIN IS NULL 

            SELECT CHAPTER,
                ROL,
                COUNT(CASE WHEN TIPO_CAPACIDAD = 'Principal' THEN 1 END) AS N_CORES,
                COUNT(CASE WHEN TIPO_CAPACIDAD = 'Complementaria' THEN 1 END) AS N_COMPLEMENTARIAS
            INTO #TMP_N_CAPACIDADES
            FROM #TMP_TIPO_CAPACIDAD
            GROUP BY  CHAPTER, ROL


            SELECT FC.FK_FECHA,
                FC.MATRICULA,
                FC.ROL,
                FC.MATRICULA_CALIFICADOR,
                FC.ROL_CALIFICADOR,
                FC.FK_CHAPTER,
                DC.DESCRIPCION AS CAPACIDAD,
                TC.TIPO_CAPACIDAD,
                FC.N_NIVEL,
                NC.N_CORES,
                NC.N_COMPLEMENTARIAS,
                COUNT(CASE WHEN FC.N_NIVEL>=2 AND TC.TIPO_CAPACIDAD = 'Principal' THEN FC.N_NIVEL END) OVER (PARTITION BY FC.FK_FECHA, FC.MATRICULA) AS MY2_CORE,
                COUNT(CASE WHEN FC.N_NIVEL>=3 AND TC.TIPO_CAPACIDAD = 'Principal' THEN FC.N_NIVEL END) OVER (PARTITION BY FC.FK_FECHA, FC.MATRICULA) AS MY3_CORE,
                COUNT(CASE WHEN FC.N_NIVEL>=4 AND TC.TIPO_CAPACIDAD = 'Principal' THEN FC.N_NIVEL END) OVER (PARTITION BY FC.FK_FECHA, FC.MATRICULA) AS MY4_CORE,
                COUNT(CASE WHEN FC.N_NIVEL>=5 AND TC.TIPO_CAPACIDAD = 'Principal' THEN FC.N_NIVEL END) OVER (PARTITION BY FC.FK_FECHA, FC.MATRICULA) AS MY5_CORE,
                COUNT(CASE WHEN FC.N_NIVEL>=2 AND TC.TIPO_CAPACIDAD = 'Complementaria' THEN FC.N_NIVEL END) OVER (PARTITION BY FC.FK_FECHA, FC.MATRICULA) AS MY2_COMPLEMENTARIA,
                COUNT(CASE WHEN FC.N_NIVEL>=4 AND TC.TIPO_CAPACIDAD = 'Complementaria' THEN FC.N_NIVEL END) OVER (PARTITION BY FC.FK_FECHA, FC.MATRICULA) AS MY4_COMPLEMENTARIA,
                COUNT(CASE WHEN FC.N_NIVEL>=5 AND TC.TIPO_CAPACIDAD = 'Complementaria' THEN FC.N_NIVEL END) OVER (PARTITION BY FC.FK_FECHA, FC.MATRICULA) AS MY5_COMPLEMENTARIA
            INTO #TMP_RESULTADOS
            FROM BCP_GDH_PA_DW.PDIGITAL.F_RESULTADO_CAPACIDAD FC
                LEFT JOIN BCP_GDH_PA_DW.PDIGITAL.D_CHAPTER DP ON FC.FK_CHAPTER=DP.PK_CHAPTER
                LEFT JOIN BCP_GDH_PA_DW.PDIGITAL.D_CAPACIDAD DC ON FC.FK_CAPACIDAD=DC.PK_CAPACIDAD
                LEFT JOIN #TMP_TIPO_CAPACIDAD TC ON DP.DESCRIPCION=TC.CHAPTER AND
                                                FC.ROL=TC.ROL AND
                                                DC.DESCRIPCION=TC.CAPACIDAD
                LEFT JOIN #TMP_N_CAPACIDADES NC ON DP.DESCRIPCION=NC.CHAPTER AND
                                                FC.ROL=NC.ROL
            WHERE FK_FECHA = @FECHA_RESULTADO    

            SELECT 
                FK_FECHA,
                MATRICULA,
                ROL,
                MATRICULA_CALIFICADOR,
                ROL_CALIFICADOR,
                FK_CHAPTER,
                CAPACIDAD,
                TIPO_CAPACIDAD,
                N_NIVEL,
                CASE
                    WHEN MY4_CORE >= N_CORES AND MY5_CORE >= 2 AND MY5_COMPLEMENTARIA>=2 THEN 5
                    WHEN MY4_CORE >= N_CORES AND MY4_COMPLEMENTARIA >=2 THEN 4
                    WHEN MY3_CORE >= N_CORES AND MY2_COMPLEMENTARIA >= N_COMPLEMENTARIAS*0.5 THEN 3
                    WHEN MY3_CORE >= N_CORES*0.5 AND MY2_CORE >= N_CORES THEN 2
                    WHEN MY2_CORE >= N_CORES*0.5 THEN 1
                    ELSE 0
                END AS N_NIVEL_EXPERTISE
            INTO #TMP_RESULTADOS_PREV_NE
            FROM #TMP_RESULTADOS

            SELECT 
                DISTINCT 
                SC.FK_FECHA,
                SC.MATRICULA,
                SC.ROL,
                SC.MATRICULA_CALIFICADOR,
                SC.ROL_CALIFICADOR,
                SC.FK_CHAPTER,
                SC.N_NIVEL_EXPERTISE,
                CASE
                    WHEN SC.N_NIVEL_EXPERTISE = 0 THEN 'Pre novato'
                    ELSE SN.DESCRIPCION
                END AS NIVEL_EXPERTISE
            INTO #TMP_RESULTADOS_DOMAIN_EXPERTISE
            FROM #TMP_RESULTADOS_PREV_NE SC
                LEFT JOIN #TMP_STAGE_NIVEL SN ON SC.N_NIVEL_EXPERTISE=SN.N_NIVEL

            
            -- INSERTANDO RESULTADO COMPORTAMIENTO
      SELECT *,
                   COUNT(CASE WHEN N_NIVEL>=0 THEN N_NIVEL END) OVER (PARTITION BY FK_FECHA, MATRICULA) AS MY0,
                   COUNT(CASE WHEN N_NIVEL>=1 THEN N_NIVEL END) OVER (PARTITION BY FK_FECHA, MATRICULA) AS MY1,
                   COUNT(CASE WHEN N_NIVEL>=2 THEN N_NIVEL END) OVER (PARTITION BY FK_FECHA, MATRICULA) AS MY2,
                   COUNT(CASE WHEN N_NIVEL>=3 THEN N_NIVEL END) OVER (PARTITION BY FK_FECHA, MATRICULA) AS MY3,
                   COUNT(CASE WHEN N_NIVEL>=4 AND FK_COMPORTAMIENTO=4 THEN N_NIVEL END) OVER (PARTITION BY FK_FECHA, MATRICULA) AS MY4_DOMAIN_EXPERTISE,
                   COUNT(CASE WHEN N_NIVEL>=4 AND FK_COMPORTAMIENTO<>4 THEN N_NIVEL END) OVER (PARTITION BY FK_FECHA, MATRICULA) AS MY4_OTROS,
                   COUNT(CASE WHEN N_NIVEL>=5 AND FK_COMPORTAMIENTO=4 THEN N_NIVEL END) OVER (PARTITION BY FK_FECHA, MATRICULA) AS MY5_DOMAIN_EXPERTISE,
                   COUNT(N_NIVEL) OVER (PARTITION BY FK_FECHA, MATRICULA) AS N_TOTAL
            INTO #TMP_RESULTADO_COMPORTAMIENTO
            FROM
            (
                SELECT SC.FECHA AS FK_FECHA,
                    SC.MATRICULA,
                    SC.ROL,
                    SC.MATRICULA_CALIFICADOR,
                    SC.ROL_CALIFICADOR,
                    DC.PK_CHAPTER AS FK_CHAPTER,
                    DP.PK_COMPORTAMIENTO AS FK_COMPORTAMIENTO,
                    SC.N_NIVEL,
                    SN.DESCRIPCION
                FROM #TMP_STAGE_RESULTADO_COMPORTAMIENTO SC
                    LEFT JOIN BCP_GDH_PA_DW.PDIGITAL.D_CHAPTER DC ON SC.CHAPTER=DC.DESCRIPCION
                    LEFT JOIN BCP_GDH_PA_DW.PDIGITAL.D_COMPORTAMIENTO DP ON SC.COMPORTAMIENTO=DP.DESCRIPCION
                    LEFT JOIN #TMP_STAGE_NIVEL SN ON SC.N_NIVEL=SN.N_NIVEL
                UNION ALL
                SELECT FK_FECHA,
                       MATRICULA,
                       ROL,
                       MATRICULA_CALIFICADOR,
                       ROL_CALIFICADOR,
                       FK_CHAPTER,
                       4 AS FK_COMPORTAMIENTO,-- DOMAIN EXPERTISE
                       N_NIVEL_EXPERTISE AS N_NIVEL,
                       NIVEL_EXPERTISE AS DESCRIPCION
                FROM #TMP_RESULTADOS_DOMAIN_EXPERTISE
            ) T
            
            INSERT INTO BCP_GDH_PA_DW.PDIGITAL.F_RESULTADO_COMPORTAMIENTO(FK_FECHA,MATRICULA,ROL,MATRICULA_CALIFICADOR,ROL_CALIFICADOR,FK_CHAPTER,FK_COMPORTAMIENTO,N_NIVEL,NIVEL)
            SELECT FK_FECHA,
                    MATRICULA,
                    ROL,
                    MATRICULA_CALIFICADOR,
                    ROL_CALIFICADOR,
                    FK_CHAPTER,
                    FK_COMPORTAMIENTO,
                    N_NIVEL,
                    DESCRIPCION
            FROM #TMP_RESULTADO_COMPORTAMIENTO

            SELECT  DISTINCT FK_FECHA,
                    MATRICULA,
                    ROL,
                    MATRICULA_CALIFICADOR,
                    ROL_CALIFICADOR,
                    FK_CHAPTER,
                    CASE 
                        WHEN MY5_DOMAIN_EXPERTISE >= 1 THEN 5
                        WHEN MY4_DOMAIN_EXPERTISE >= 1 AND MY4_OTROS >=1 THEN 4
                        WHEN MY3 >= N_TOTAL THEN 3
                        WHEN MY2 >= N_TOTAL THEN 2
                        WHEN MY1 >= N_TOTAL THEN 1
                        WHEN MY0 >= N_TOTAL THEN 0
                    END AS N_NIVEL
            INTO #TMP_RESULTADO_FINAL_PREV
            FROM #TMP_RESULTADO_COMPORTAMIENTO

            SELECT SF.FK_FECHA,
                   SF.MATRICULA,
                   SF.ROL,
                   SF.MATRICULA_CALIFICADOR,
                   SF.ROL_CALIFICADOR,
                   SF.FK_CHAPTER,
                   SF.N_NIVEL,
                   CASE
                    WHEN SF.N_NIVEL = 0 THEN 'Pre novato'
                    ELSE SN.DESCRIPCION
                   END AS NIVEL
            INTO #TMP_RESULTADO_FINAL
            FROM #TMP_RESULTADO_FINAL_PREV SF
                LEFT JOIN #TMP_STAGE_NIVEL SN ON SF.N_NIVEL=SN.N_NIVEL

            INSERT INTO BCP_GDH_PA_DW.PDIGITAL.F_RESULTADO_EXPERTISE(FK_FECHA,MATRICULA,ROL,MATRICULA_CALIFICADOR,ROL_CALIFICADOR,FK_CHAPTER,N_NIVEL,NIVEL)
            SELECT FK_FECHA,
                   MATRICULA,
                   ROL,
                   MATRICULA_CALIFICADOR,
                   ROL_CALIFICADOR,
                   FK_CHAPTER,
                   N_NIVEL,
                   NIVEL
            FROM #TMP_RESULTADO_FINAL
        END