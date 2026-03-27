# API Dash MCP Server

## 1. Prerequisites

```bash
cd packages/apidash_storage
dart pub get

cd ../apidash_mcp
dart pub get
```

## 2. Set MCP in VS Code

Create or update `.vscode/mcp.json`:

```json
{
	"servers": {
		"apidash": {
			"type": "stdio",
			"command": "dart",
			"args": [
				"run",
				"apidash/packages/apidash_mcp/bin/server.dart"
			],
			"env": {
				"APIDASH_WORKSPACE_PATH": "/absolute/path/to/your/his/workspace"
			}
		}
	},
	"inputs": []
}
```

Replace `/absolute/path/to/your/his/workspace` with your HIS workspace path.

## 3. Start the server

After saving `.vscode/mcp.json`, restart MCP in VS Code (or reload the window).

The server starts through the `dart run .../bin/server.dart` command from the config.

## 4. List tools

In Copilot Chat, run:

```text
List all tools available on MCP server apidash.
```

You should see:

```text
list_collections
```

## 5. Execute tool

In Copilot Chat, run:

```text
Show all API Dash collections by invoking MCP tool list_collections on server apidash.
```

This executes `list_collections` and returns the collections from your HIS workspace.

If collections are not appearing yet, or you want to verify that multiple collections are listed correctly, you can add one manually in your HIS workspace or create it using the CLI.

```bash
cd packages/apidash_cli
dart run bin/apidash_cli.dart exec --url=https://httpbin.org/get --method=GET --collection=<collection_name> --save
```

