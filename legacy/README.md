# Project Toolkit CLI

This project includes a set of scripts to manage the development, building, and deployment of the application. The scripts are encapsulated in a CLI script that provides various commands to streamline common tasks.

## Prerequisites

- Docker
- Git

## Usage

The CLI script provides several commands to manage the project. Below are the available commands and their descriptions.

### Commands

#### `install`

Install the project dependencies.

```sh
sh cli install
```

#### `run`

Run a command in a fresh Docker instance.

```sh
sh cli run <command>
```

Example:

```sh
sh cli run npm install
```

#### `shell`

Start a shell in a fresh Docker instance.

```sh
sh cli shell
```

#### `build`

Build the Docker images and push them to the registry.

```sh
sh cli build
```

#### `kit`

Run DevOps commands.

```sh
sh cli kit [subcommand]
```

Subcommands:

- `override`: Apply templates using the script.

#### `--help` or `-h`

Display the help message.

```sh
sh cli --help
```

## Example Workflow

Here is an example of how you might use the CLI script in your development workflow:

1. **Install dependencies**:

   ```sh
   sh cli install
   ```

2. **Run a command in a fresh Docker instance**:

   ```sh
   sh cli run <command>
   ```

3. **Start a shell in a fresh Docker instance**:

   ```sh
   sh cli shell
   ```

4. **Build and push Docker images**:

   ```sh
   sh cli build
   ```

5. **Apply DevOps templates**:

   ```sh
   sh cli kit override
   ```

## Internal Use Only ⚠️

This project is intended for internal use within the company. Please do not distribute or share outside the organization.
