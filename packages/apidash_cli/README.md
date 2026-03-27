# API Dash CLI

## Prerequisites

```bash
cd packages/apidash_storage
dart pub get

cd packages/apidash_cli
dart pub get
```

## Local Run

1. Go to the CLI package.

```bash
cd packages/apidash_cli
```

2. Install dependencies.

```bash
dart pub get
```

3. Create a workspace.

```bash
dart run bin/apidash_cli.dart init ~/workspace-path
```

4. Export workspace path.

```bash
export APIDASH_WORKSPACE_PATH=~/workspace-path
```

5. Execute request and save.

```bash
dart run apidash exec --url=https://httpbin.org/get --method=GET --save
```
OR

```bash
dart run apidash exec --url=https://httpbin.org/get --method=GET 
```

## Note

If you want to create a new collection, add it manually at your HIS workspace path, or pass a collection flag in a request.

```bash
dart run bin/apidash_cli.dart exec --url=https://httpbin.org/get --method=GET --collection=<col_name> --save
```


## Global Run

1. Go to the CLI package.

```bash
cd packages/apidash_cli
```

2. Activate globally from local source.

```bash
dart pub global activate --source path .
```

3. Create a workspace.

```bash
apidash init ~/workspace-path
```

4. Export workspace path.

```bash
export APIDASH_WORKSPACE_PATH=~/workspace-path
```

5. Execute request and save.


```bash
apidash exec --url=https://httpbin.org/get --method=GET --save
```
OR

```bash
apidash exec --url=https://httpbin.org/get --method=GET 
```