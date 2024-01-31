# Man Pager Generation with GitHub Actions

This repository contains a GitHub Actions workflow that automatically generates man pages from Markdown files whenever you push changes to the repository.

Please replace `YourGitHubUsername` and `your-repository` with your actual GitHub username and repository name.

# Man Pager Generation Localy
## How to make a Manual pager
### Quick start
```bash 
sudo apt update && sudo apt install pandoc -y
```

```bash
{
cd /tmp 
wget https://gist.githubusercontent.com/eddieantonio/55752dd76a003fefb562/raw/38f6eb9de250feef22ff80da124b0f439fba432d/hello.1.md
pandoc --standalone --to man ./hello.1.md -o ./hello.1
man ./hello.1
}
```

[template](https://gist.githubusercontent.com/eddieantonio/55752dd76a003fefb562/raw/38f6eb9de250feef22ff80da124b0f439fba432d/hello.1.md)

