# Dicionário de Dados – Gold

## **Entidade: dim_air**

Descrição: Define dados sobre as companhias aéreas.

| Atributo | Tipo         | Descrição                                                |
| -------- | ------------ | -------------------------------------------------------- |
| srk_air  | serial       | Identificador único da companhia aérea (chave primária). |
| air_iat  | varchar(3)   | Código IATA da companhia aérea (chave única).            |
| air_nam  | varchar(100) | Nome da companhia aérea.                                 |

---

## **Entidade: dim_apt**

Descrição: Define dados sobre os aeroportos.

| Atributo | Tipo             | Descrição                                          |
| -------- | ---------------- | -------------------------------------------------- |
| srk_apt  | serial           | Identificador único do aeroporto (chave primária). |
| apt_iat  | varchar(3)       | Código IATA do aeroporto (chave única).            |
| apt_nam  | varchar(100)     | Nome do aeroporto.                                 |
| ste_cod  | varchar(3)       | Código do estado onde o aeroporto se encontra.     |
| ste_nam  | varchar(100)     | Nome do estado onde o aeroporto se encontra.       |
| cty_nam  | varchar(100)     | Nome da cidade onde o aeroporto se encontra.       |
| lat_val  | double precision | Latitude do aeroporto.                             |
| lon_val  | double precision | Longitude do aeroporto.                            |

---

## **Entidade: dim_dat**

Descrição: Define dados sobre as datas.

| Atributo | Tipo     | Descrição                                     |
| -------- | -------- | --------------------------------------------- |
| srk_dat  | serial   | Identificador único da data (chave primária). |
| ful_dat  | date     | Data completa (AAAA-MM-DD).                   |
| yer      | smallint | Ano.                                          |
| mth      | smallint | Mês.                                          |
| day      | smallint | Dia do mês.                                   |
| dow      | smallint | Dia da semana (1=Segunda, 7=Domingo).         |
| qtr      | smallint | Trimestre (1 a 4).                            |
| hol_flg  | boolean  | Indica se é feriado (True/False).             |

---

## **Entidade: fat_flt**

Descrição: Define dadso sobre os voos.

| Atributo | Tipo             | Descrição                                           |
| -------- | ---------------- | --------------------------------------------------- |
| srk_flt  | int              | Identificador único do voo (chave primária).        |
| srk_dat  | int              | Chave estrangeira para dim_dat (FK).                |
| srk_air  | int              | Chave estrangeira para dim_air (FK).                |
| srk_ori  | int              | Chave estrangeira para dim_apt (origem) (FK).       |
| srk_dst  | int              | Chave estrangeira para dim_apt (destino) (FK).      |
| sch_dep  | timestamp        | Horário programado de partida (HHMM).               |
| dep_tme  | timestamp        | Horário real de partida (HHMM).                     |
| sch_arr  | timestamp        | Horário programado de chegada (HHMM).               |
| arr_tme  | timestamp        | Horário real de chegada (HHMM).                     |
| dis_val  | double precision | Distância do voo (milhas/km).                       |
| air_tme  | double precision | Tempo em voo (em minutos).                          |
| elp_tme  | double precision | Tempo total do voo (em minutos).                    |
| sch_tme  | double precision | Tempo de voo programado (em minutos).               |
| dep_dly  | double precision | Atraso na decolagem (em minutos).                   |
| arr_dly  | double precision | Atraso na chegada (em minutos).                     |
| sys_dly  | double precision | Atraso devido ao sistema aéreo (em minutos).        |
| sec_dly  | double precision | Atraso devido a questões de segurança (em minutos). |
| air_dly  | double precision | Atraso devido à companhia aérea (em minutos).       |
| acf_dly  | double precision | Atraso por aeronave anterior atrasada (em minutos). |
| wea_dly  | double precision | Atraso devido ao clima (em minutos).                |
| ovn_flg  | boolean          | Indica se um voo atravesou o dia.                   |
