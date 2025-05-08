=== "Supported Commands"

- **`install`**  
  Installs one or more GitHub runners using the provided configuration or interactively prompted values.

- **`purge` / `remove`**  
  Removes runners based on the provided runner name series and target organization or repository.

- **`status`**  
  Quietly checks if any `actions.runner` services are currently running on the system.

=== "Available Switches"

| Switch             | Description                                                                 |
|--------------------|-----------------------------------------------------------------------------|
| `gh_token`         | GitHub token with admin rights to manage self-hosted runners.               |
| `runner_name`      | Name prefix for the runner series (default: `armbian`).                     |
| `start`            | Start index of the runner series (e.g., `01`).                              |
| `stop`             | End index of the runner series (e.g., `05`).                                |
| `label_primary`    | Labels for the first runner (default: `alfa`).                              |
| `label_secondary`  | Labels for additional runners (default: `fast,images`).                     |
| `organisation`     | GitHub organization name (default: `armbian`).                              |
| `owner`            | GitHub user or organization owner (used for repo-level runners).            |
| `repository`       | GitHub repository name (used for repo-level runners).                       |

=== "Behavior"

- Prompts the user for missing switches via `dialog` **only in interactive mode**.
- Supports bulk installation of runners using sequential numbering (`start` to `stop`).
- Calls internal `actions.runner.install` and `actions.runner.remove` helpers.
- Returns `0` if any runner services are active, `1` otherwise (for scripting use).
- Suppresses errors and outputs when checking status to remain quiet in background use.
