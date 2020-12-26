# Microblog no Protheus
Este projeto será a base para as publicações na plataforma [dev.to](https://dev.to/) sobre Apis Rest com Protheus.

A primeira publicação está disponível [aqui](https://dev.to/josimar_jr_/um-microblog-usando-protheus-rest-server-parte-1-5999).

## Ambiente utilizado
O ambiente foi criado a partir dos artefatos disponibilizados na liberação de outubro.
Abaixo os detalhes dos artefatos recuperados usando o endpoint `/shiftf6`.

```json
{
    "server": {
        "build": "7.00.191205P-20201029",
        "type": "64",
        "version": "19.3.1.1",
        "codepage": "cp1252"
    },
    "dbaccess": {
        "build": "20200606-20201012",
        "db_api_build": "20200606-20201026"
    },
    "license": {
        "version": "2014 - 3.2.0"
    },
    "os_server": {
        "name": "OS Version .........: Windows 10 [Version 10.0.15063]\nOS Platform ........: Windows NT Based (x64)\nOS Version Info ....: \nOS Power Scheme ....: High Performance\n"
    },
    "protheus": {
        "version": "TOTVS Construção e Projetos",
        "dictionary_in_db": true,
        "localfiles": "CTREE",
        "environment": "P12MICROBLOG",
        "repository_release": "12.1.027 - Out  2020",
        "dictionary_release": "12.1.027 - Out  2020"
    },
    "database": {
        "name": "MSSQL"
    },
    "lib": {
        "date": "20201013_16576",
        "version": "20201009",
        "commit_id": "bae94a3cad4e71ef3ee584894c8e28383b7195ee"
    }
}
```

## Requisições com `POSTMAN`
Neste repositório tem os arquivos de coleção do `POSTMAN` para ser utilizado e importado para conseguir fazer os mesmos testes realizados.

> `resources/postman/`

## Réplica do ambiente
Este ambiente foi criado com dicionário no banco de dados e caso utilize Microsoft Sql Server é possível restaurar utilizado o backup disponível neste [arquivo](https://drive.google.com/file/d/1D6aboQhDGn9Ow-MCnUHpfxE0b8gftfwy/view).
Senha do usuário `admin` : `senha!forte!`
