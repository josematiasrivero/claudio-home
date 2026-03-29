# CLAUDE.md

## Port Allocation Convention

Each app gets a range of `X000–X999` where `X` is the app number:

| App           | X |
|---------------|---|
| cotizador     | 3 |
| tvn           | 4 |
| bearme        | 5 |
| invoiceme     | 6 |

### Port assignments within each range

| Port      | Service          |
|-----------|------------------|
| X000–X010 | App/modules      |
| X011      | pgweb            |
| X012      | MinIO            |
| X013      | Remote VS Code   |
