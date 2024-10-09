# SAS

Based on [the current docs](https://documentation.sas.com/doc/en/pgmsascdc/v_014/casmopt/casmopt_clpsolver_toc.htm), SAS' constraint-programming interface is still burgeoning: 

- [ALLDIFF](https://documentation.sas.com/doc/en/pgmsascdc/v_014/casmopt/casmopt_clpsolver_syntax06.htm): `MOI.AllDifferent`
- [CUMULATIVE](https://documentation.sas.com/doc/en/pgmsascdc/v_014/casmopt/casmopt_clpsolver_syntax07.htm): `CP.CumulativeResource`
- [ELEMENT](https://documentation.sas.com/doc/en/pgmsascdc/v_014/casmopt/casmopt_clpsolver_syntax08.htm)
- [GCC](https://documentation.sas.com/doc/en/pgmsascdc/v_014/casmopt/casmopt_clpsolver_syntax09.htm)
- [LEXICO](https://documentation.sas.com/doc/en/pgmsascdc/v_014/casmopt/casmopt_clpsolver_syntax10.htm)
- [PACK](https://documentation.sas.com/doc/en/pgmsascdc/v_014/casmopt/casmopt_clpsolver_syntax11.htm): `CP.BinPacking` and variants
- [REIFY](https://documentation.sas.com/doc/en/pgmsascdc/v_014/casmopt/casmopt_clpsolver_syntax12.htm): `CP.Reify`

There are more features in [the scheduling module](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax.htm):

- [ACTIVITY](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax03.htm): TODO
- [ALLDIFF](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax04.htm): `MOI.AllDifferent`
- [CUMULATIVE](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax06.htm): `CP.CumulativeResource`
- [ARRAY](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax05.htm)
- [ELEMENT](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax07.htm)
- [FOREACH](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax08.htm)
- [GCC](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax09.htm)
- [LEXICO](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax10.htm)
- [LINCON](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax11.htm): standard MOI
- [OBJ](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax12.htm): standard MOI
- [PACK](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax13.htm): `CP.BinPacking` and variants
- [REIFY](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax14.htm): `CP.Reify`
- [REQUIRES](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax15.htm)
- [RESOURCE](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax16.htm)
- [SCHEDULE](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax17.htm)
- [VARIABLE](https://documentation.sas.com/doc/en/pgmsascdc/v_014/orcpug/orcpug_clp_syntax18.htm)
