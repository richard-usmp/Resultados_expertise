import pandas as pd
import os
from tkinter import messagebox as MessageBox

carpeta_entrada = 'Excel_entrada'
archivos_excel = [archivo for archivo in os.listdir(carpeta_entrada) if archivo.endswith('.xlsx')]

for archivo in archivos_excel:
    capacidad_categoria = pd.read_excel('CapacidadCategoria\diccionario_CapacidadCategoria.xlsx', sheet_name='CapacidadCategoria')
    ruta_archivo = os.path.join(carpeta_entrada, archivo)
    resultado_capacidad = pd.read_excel(ruta_archivo, sheet_name='CapacidadesV1')
    resultado_competencia = pd.read_excel(ruta_archivo, sheet_name='ComportamientoV1')


    tmp_stage_nivel = pd.DataFrame({
        'N_NIVEL': [0, 1, 2, 3, 4, 5],
        'DESCRIPCION': ['No evidenciado', 'Novato', 'Principiante avanzado', 'Competente', 'Proficiente', 'Master']
    })

    resultado_capacidad['CONCAT'] = resultado_capacidad.ROL.str.cat(resultado_capacidad.CHAPTER.str.cat(resultado_capacidad.CAPACIDAD, sep=''), sep='')
    capacidad_categoria['CONCAT'] = capacidad_categoria.ROL.str.cat(capacidad_categoria.CHAPTER.str.cat(capacidad_categoria.CAPACIDAD, sep=''), sep='')
    capacidad_categoria = capacidad_categoria.drop(['CHAPTER', 'ROL', 'CAPACIDAD'], axis=1)
    resultado_capacidad = resultado_capacidad.merge(capacidad_categoria, on='CONCAT', how='left')


    resultado_capacidad['aux_MY2_CORE'] = [1 if (x['N_NIVEL'] >= 2) and (x['SUBCATEGORIA_CAPACIDAD'] == 'PRINCIPAL') else 0 for i, x in resultado_capacidad.iterrows()]
    n_c1 = resultado_capacidad.groupby('MATRICULA')['aux_MY2_CORE'].transform('sum')
    resultado_capacidad['MY2_CORE'] = n_c1

    resultado_capacidad['aux_MY3_CORE'] = [1 if (x['N_NIVEL'] >= 3) and (x['SUBCATEGORIA_CAPACIDAD'] == 'PRINCIPAL') else 0 for i, x in resultado_capacidad.iterrows()]
    n_c1 = resultado_capacidad.groupby('MATRICULA')['aux_MY3_CORE'].transform('sum')
    resultado_capacidad['MY3_CORE'] = n_c1

    resultado_capacidad['aux_MY4_CORE'] = [1 if (x['N_NIVEL'] >= 4) and (x['SUBCATEGORIA_CAPACIDAD'] == 'PRINCIPAL') else 0 for i, x in resultado_capacidad.iterrows()]
    n_c1 = resultado_capacidad.groupby('MATRICULA')['aux_MY4_CORE'].transform('sum')
    resultado_capacidad['MY4_CORE'] = n_c1

    resultado_capacidad['aux_MY5_CORE'] = [1 if (x['N_NIVEL'] >= 5) and (x['SUBCATEGORIA_CAPACIDAD'] == 'PRINCIPAL') else 0 for i, x in resultado_capacidad.iterrows()]
    n_c1 = resultado_capacidad.groupby('MATRICULA')['aux_MY5_CORE'].transform('sum')
    resultado_capacidad['MY5_CORE'] = n_c1

    resultado_capacidad['aux_MY2_COMPLEMENTARIA'] = [1 if (x['N_NIVEL'] >= 2) and (x['SUBCATEGORIA_CAPACIDAD'] == 'COMPLEMENTARIA') else 0 for i, x in resultado_capacidad.iterrows()]
    n_c1 = resultado_capacidad.groupby('MATRICULA')['aux_MY2_COMPLEMENTARIA'].transform('sum')
    resultado_capacidad['MY2_COMPLEMENTARIA'] = n_c1

    resultado_capacidad['aux_MY4_COMPLEMENTARIA'] = [1 if (x['N_NIVEL'] >= 4) and (x['SUBCATEGORIA_CAPACIDAD'] == 'COMPLEMENTARIA') else 0 for i, x in resultado_capacidad.iterrows()]
    n_c1 = resultado_capacidad.groupby('MATRICULA')['aux_MY4_COMPLEMENTARIA'].transform('sum')
    resultado_capacidad['MY4_COMPLEMENTARIA'] = n_c1

    resultado_capacidad['aux_MY5_COMPLEMENTARIA'] = [1 if (x['N_NIVEL'] >= 5) and (x['SUBCATEGORIA_CAPACIDAD'] == 'COMPLEMENTARIA') else 0 for i, x in resultado_capacidad.iterrows()]
    n_c1 = resultado_capacidad.groupby('MATRICULA')['aux_MY5_COMPLEMENTARIA'].transform('sum')
    resultado_capacidad['MY5_COMPLEMENTARIA'] = n_c1


    count_principal = resultado_capacidad.groupby('MATRICULA')['SUBCATEGORIA_CAPACIDAD'].apply(lambda x: (x == 'PRINCIPAL').sum())
    resultado_capacidad['N_CORES'] = resultado_capacidad['MATRICULA'].map(count_principal)

    count_complementarias = resultado_capacidad.groupby('MATRICULA')['SUBCATEGORIA_CAPACIDAD'].apply(lambda x: (x == 'COMPLEMENTARIA').sum())
    resultado_capacidad['N_COMPLEMENTARIAS'] = resultado_capacidad['MATRICULA'].map(count_complementarias)

    resultado_capacidad['N_NIVEL_EXPERTISE'] = 0

    grupo_matricula = resultado_capacidad.groupby('MATRICULA')

    for matricula, grupo in grupo_matricula:
        mask_5 = (grupo['MY4_CORE'] >= grupo['N_CORES']) & (grupo['MY5_CORE'] >= 2) & (grupo['MY5_COMPLEMENTARIA'] >= 2)
        mask_4 = (grupo['MY4_CORE'] >= grupo['N_CORES']) & (grupo['MY4_COMPLEMENTARIA'] >= 2)
        mask_3 = (grupo['MY3_CORE'] >= grupo['N_CORES']) & (grupo['MY2_COMPLEMENTARIA'] >= grupo['N_COMPLEMENTARIAS']*0.5)
        mask_2 = (grupo['MY3_CORE'] >= grupo['N_CORES']*0.5) & (grupo['MY2_CORE'] >= grupo['N_CORES'])
        mask_1 = (grupo['MY2_CORE'] >= grupo['N_CORES']*0.5)

        if mask_5.any():
            grupo['N_NIVEL_EXPERTISE'] = 5
        elif mask_4.any():
            grupo['N_NIVEL_EXPERTISE'] = 4
        elif mask_3.any():
            grupo['N_NIVEL_EXPERTISE'] = 3
        elif mask_2.any():
            grupo['N_NIVEL_EXPERTISE'] = 2
        elif mask_1.any():
            grupo['N_NIVEL_EXPERTISE'] = 1

        resultado_capacidad.loc[resultado_capacidad['MATRICULA'] == matricula] = grupo


    df_dimensiones = resultado_capacidad.drop_duplicates(subset=['MATRICULA', 'ROL', 'MATRICULA_CALIFICADOR', 'ROL_CALIFICADOR', 'CHAPTER', 'N_NIVEL_EXPERTISE'])
    df_dimensiones['COMPETENCIA'] = 'Domain expertise'
    df_dimensiones = df_dimensiones[['MATRICULA', 'ROL', 'MATRICULA_CALIFICADOR', 'ROL_CALIFICADOR', 'CHAPTER', 'COMPETENCIA', 'N_NIVEL_EXPERTISE']]
    df_dimensiones.rename(columns={'N_NIVEL_EXPERTISE': 'N_NIVEL'}, inplace=True)
    df_dimensiones = pd.concat([df_dimensiones, resultado_competencia])

    resultado_capacidad = resultado_capacidad.drop(['CONCAT', 'aux_MY2_CORE', 'MY2_CORE', 'aux_MY3_CORE', 'MY3_CORE', 'aux_MY4_CORE', 'MY4_CORE', 'aux_MY5_CORE', 'MY5_CORE', 'aux_MY2_COMPLEMENTARIA', 'MY2_COMPLEMENTARIA', 'aux_MY4_COMPLEMENTARIA', 'MY4_COMPLEMENTARIA', 'aux_MY5_COMPLEMENTARIA', 'MY5_COMPLEMENTARIA', 'N_CORES', 'N_COMPLEMENTARIAS'], axis=1)
    #resultado_capacidad.to_excel('f_resultado_capacidad.xlsx', index=False)

    #df_dimensiones.to_excel('f_resultado_comportamiento.xlsx', index=False)



    df_dimensiones['aux_MY0'] = [1 if (x['N_NIVEL'] >= 0) else 0 for i, x in df_dimensiones.iterrows()]
    n_c1 = df_dimensiones.groupby('MATRICULA')['aux_MY0'].transform('sum')
    df_dimensiones['MY0'] = n_c1

    df_dimensiones['aux_MY1'] = [1 if (x['N_NIVEL'] >= 1) else 0 for i, x in df_dimensiones.iterrows()]
    n_c2 = df_dimensiones.groupby('MATRICULA')['aux_MY1'].transform('sum')
    df_dimensiones['MY1'] = n_c2

    df_dimensiones['aux_MY2'] = [1 if (x['N_NIVEL'] >= 2) else 0 for i, x in df_dimensiones.iterrows()]
    n_c3 = df_dimensiones.groupby('MATRICULA')['aux_MY2'].transform('sum')
    df_dimensiones['MY2'] = n_c3

    df_dimensiones['aux_MY3'] = [1 if (x['N_NIVEL'] >= 3) else 0 for i, x in df_dimensiones.iterrows()]
    n_c4 = df_dimensiones.groupby('MATRICULA')['aux_MY3'].transform('sum')
    df_dimensiones['MY3'] = n_c4

    df_dimensiones['aux_MY4_DOMAIN_EXPERTISE'] = [1 if (x['N_NIVEL'] >= 4) and (x['COMPETENCIA'] == 'Domain expertise') else 0 for i, x in df_dimensiones.iterrows()]
    n_c5 = df_dimensiones.groupby('MATRICULA')['aux_MY4_DOMAIN_EXPERTISE'].transform('sum')
    df_dimensiones['MY4_DOMAIN_EXPERTISE'] = n_c5

    df_dimensiones['aux_MY4_OTROS'] = [1 if (x['N_NIVEL'] >= 4) and (x['COMPETENCIA'] != 'Domain expertise') else 0 for i, x in df_dimensiones.iterrows()]
    n_c6 = df_dimensiones.groupby('MATRICULA')['aux_MY4_OTROS'].transform('sum')
    df_dimensiones['MY4_OTROS'] = n_c6

    df_dimensiones['aux_MY5_DOMAIN_EXPERTISE'] = [1 if (x['N_NIVEL'] >= 5) and (x['COMPETENCIA'] == 'Domain expertise') else 0 for i, x in df_dimensiones.iterrows()]
    n_c7 = df_dimensiones.groupby('MATRICULA')['aux_MY5_DOMAIN_EXPERTISE'].transform('sum')
    df_dimensiones['MY5_DOMAIN_EXPERTISE'] = n_c7


    df_dimensiones['N_NIVEL_EXPERTISE'] = 0


    grupo_matricula = df_dimensiones.groupby('MATRICULA')

    for matricula, grupo in grupo_matricula:
        mask_5 = (grupo['MY5_DOMAIN_EXPERTISE'] >= 1)
        mask_4 = (grupo['MY4_DOMAIN_EXPERTISE'] >= 1) & (grupo['MY4_OTROS'] >= 1)
        mask_3 = (grupo['MY3'] >= 4)
        mask_2 = (grupo['MY2'] >= 4)
        mask_1 = (grupo['MY1'] >= 4)
        mask_0 = (grupo['MY0'] >= 4)

        if mask_5.any():
            grupo['N_NIVEL_EXPERTISE'] = 5
        elif mask_4.any():
            grupo['N_NIVEL_EXPERTISE'] = 4
        elif mask_3.any():
            grupo['N_NIVEL_EXPERTISE'] = 3
        elif mask_2.any():
            grupo['N_NIVEL_EXPERTISE'] = 2
        elif mask_1.any():
            grupo['N_NIVEL_EXPERTISE'] = 1
        elif mask_0.any():
            grupo['N_NIVEL_EXPERTISE'] = 0

        df_dimensiones.loc[df_dimensiones['MATRICULA'] == matricula] = grupo

    df_resultado_expertise = df_dimensiones.drop_duplicates(subset=['MATRICULA', 'ROL', 'MATRICULA_CALIFICADOR', 'ROL_CALIFICADOR', 'CHAPTER', 'N_NIVEL_EXPERTISE']) ###
    df_resultado_expertise = df_resultado_expertise[['MATRICULA', 'ROL', 'MATRICULA_CALIFICADOR', 'ROL_CALIFICADOR', 'CHAPTER', 'N_NIVEL_EXPERTISE']]
    df_resultado_expertise.rename(columns={'N_NIVEL_EXPERTISE': 'N_NIVEL'}, inplace=True)

    #df_resultado_expertise.to_excel('f_resultado_expertise.xlsx', index=False)

    df_dimensiones = df_dimensiones.drop(['aux_MY0', 'MY0', 'aux_MY1', 'MY1', 'aux_MY2', 'MY2', 'aux_MY3', 'MY3', 'aux_MY4_DOMAIN_EXPERTISE', 'MY4_DOMAIN_EXPERTISE', 'aux_MY4_OTROS', 'MY4_OTROS', 'aux_MY5_DOMAIN_EXPERTISE', 'MY5_DOMAIN_EXPERTISE', 'N_NIVEL_EXPERTISE'], axis=1)

    carpeta_base = 'Resultado/'
    nombre_base = 'Resultados_Expertise'

    contador = 0

    while True:
        contador += 1

        nombre_ubicacion_archivo = carpeta_base + nombre_base + '_' + str(contador) + '_' + str(archivo)  + '.xlsx'
        print(nombre_ubicacion_archivo)
        if os.path.exists(nombre_ubicacion_archivo):
            continue
        else:
            with pd.ExcelWriter(nombre_ubicacion_archivo) as writer:
                resultado_capacidad.to_excel(writer, sheet_name='f_resultado_capacidad', index=False)
                df_dimensiones.to_excel(writer, sheet_name='f_resultado_comportamiento', index=False)
                df_resultado_expertise.to_excel(writer, sheet_name='f_resultado_expertise', index=False)
            print('Archivo guardado correctamente.')
            break

    print("listo")
    MessageBox.showinfo("Mensaje", "Se generó el excel resultado en la carpeta Resultado.")