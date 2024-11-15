[![Deploy](https://github.com/diseec/placeholderforprojectid-placeholderforprojectname/actions/workflows/CD.yaml/badge.svg)](https://github.com/diseec/placeholderforprojectid-placeholderforprojectname/actions/workflows/CD.yaml)

# placeholderforprojectid placeholderforprojectname Project

This project includes a set of scripts to manage the development, building, and deployment of the placeholderforprojectid placeholderforprojectname application. The scripts are encapsulated in a `cli` script that provides various commands to streamline common tasks.

## Prerequisites

- Docker
- Git

## Usage

The `cli` script provides several commands to manage the project. Below are the available commands and their descriptions.

### Commands

#### `install`

Install the project dependencies.

```sh
sh cli install
```

#### `dev`

Start the development server.

```sh
sh cli dev
```

**Note:** This command prioritizes the local Docker image built with the `build` command. If you want to use the image from the registry, you must first pull it using the `pull` command. Additionally, if you need to add any environment variables, you must do so by adding them to the `docker-compose` environment section.

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

#### `test`

Run the tests.

```sh
sh cli test
```

#### `build`

Build the Docker images and push them to the registry.

```sh
sh cli build
```

#### `deploy`

Deploy the application to the Kubernetes cluster.

```sh
sh cli deploy
```

#### `pull`

Pull the latest changes and image from the remote repository.

```sh
sh cli pull
```

#### `release`

Merge the `main` branch into the `release` branch and push to trigger the CI/CD pipeline.

```sh
sh cli release
```

#### `pro`

Start the production server.

```sh
sh cli pro
```

**Note:** The pull policy for this command is always, meaning it will always pull the latest image from the registry. This ensures that the local environment simulates the same conditions as the production pod on the server.

#### `--help` or `-h`

Display the help message.

```sh
sh cli --help
```

## Example Workflow

Here is an example of how you might use the `cli` script in your development workflow:

1. **Install dependencies**:

   ```sh
   sh cli install
   ```

2. **Start the development server**:

   ```sh
   sh cli dev
   ```

3. **Run tests**:

   ```sh
   sh cli test
   ```

4. **Build and push Docker images**:

   ```sh
   sh cli build
   ```

5. **Release the application**:

   ```sh
   sh cli release
   ```

## Internal Use Only ⚠️

This project is intended for internal use within the company. Please do not distribute or share outside the organization.
