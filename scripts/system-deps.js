#!/usr/bin/env node

const { execSync, spawn } = require("child_process");
const path = require("path");
const fs = require("fs");

const PKG = require(path.join(__dirname, "../package.json"));

const COLORS = {
  RED: "\x1b[31m",
  GREEN: "\x1b[32m",
  YELLOW: "\x1b[33m",
  BLUE: "\x1b[34m",
  NC: "\x1b[0m",
};

class SystemDependencyManager {
  constructor() {
    this.distro = this.detectDistro();
    this.installers = new Map();
    this.registerInstallers();
  }

  log(color, message) {
    console.log(`${color}${message}${COLORS.NC}`);
  }

  detectDistro() {
    try {
      if (fs.existsSync("/etc/alpine-release")) return "alpine";
      if (
        fs.existsSync("/etc/debian_version") ||
        fs.existsSync("/etc/lsb-release")
      )
        return "ubuntu";
      try {
        execSync("which apk", { stdio: "ignore" });
        return "alpine";
      } catch {}
      try {
        execSync("which apt-get", { stdio: "ignore" });
        return "ubuntu";
      } catch {}
    } catch {}
    return "unknown";
  }

  isLinux() {
    return process.platform === "linux";
  }

  commandExists(cmd) {
    try {
      execSync(`command -v ${cmd}`, { stdio: "ignore" });
      return true;
    } catch {
      return false;
    }
  }

  // Package manager utilities
  async runPackageManager(cmd) {
    try {
      execSync(cmd, { stdio: "inherit" });
      return true;
    } catch {
      return false;
    }
  }

  async installPackage(pkg) {
    if (this.distro === "alpine") {
      return this.runPackageManager(`apk add --no-cache ${pkg}`);
    } else if (this.distro === "ubuntu") {
      return this.runPackageManager(`apt-get install -y ${pkg}`);
    }
    return false;
  }

  async updatePackageList() {
    if (this.distro === "ubuntu") {
      return this.runPackageManager("apt-get update");
    }
    return true; // Alpine doesn't need update
  }

  // Custom installer registration system
  registerInstaller(dep, installerFn) {
    this.installers.set(dep, installerFn);
  }

  // Register all custom installers
  registerInstallers() {
    // Git - basic package manager install
    this.registerInstaller("git", async () => {
      return this.installPackage("git");
    });

    // Curl - basic package manager install
    this.registerInstaller("curl", async () => {
      return this.installPackage("curl");
    });

    // Bash - basic package manager install
    this.registerInstaller("bash", async () => {
      return this.installPackage("bash");
    });

    // Docker - distro-specific handling
    this.registerInstaller("docker", async () => {
      if (this.distro === "alpine") {
        return this.installPackage("docker");
      } else if (this.distro === "ubuntu") {
        return this.installPackage("docker.io");
      }
      return false;
    });

    // // Node.js - basic package manager install
    // this.registerInstaller("nodejs", async () => {
    //   return this.installPackage("nodejs");
    // });

    // NPM - basic package manager install
    this.registerInstaller("npm", async () => {
      return this.installPackage("npm");
    });

    // YQ - basic package manager install
    this.registerInstaller("yq", async () => {
      return this.installPackage("yq");
    });

    // Yarn - NPM global install
    this.registerInstaller("yarn", async () => {
      try {
        execSync("npm install -g yarn", { stdio: "inherit" });
        return true;
      } catch {
        return false;
      }
    });

    // GitHub CLI - custom binary installation
    this.registerInstaller("gh", async () => {
      try {
        // Use the same logic as your Dockerfile
        const arch = execSync("uname -m", { encoding: "utf8" }).trim();
        let archTag;
        if (arch === "x86_64") archTag = "linux_amd64";
        else if (arch === "aarch64") archTag = "linux_arm64";
        else throw new Error(`Unsupported architecture: ${arch}`);

        const version = "2.47.0";
        const url = `https://github.com/cli/cli/releases/download/v${version}/gh_${version}_${archTag}.tar.gz`;

        execSync(
          `
                    mkdir -p /tmp/gh &&
                    cd /tmp/gh &&
                    wget "${url}" &&
                    tar -xzf "gh_${version}_${archTag}.tar.gz" &&
                    sudo mv gh_*/bin/gh /usr/local/bin/ &&
                    sudo chmod +x /usr/local/bin/gh &&
                    cd / &&
                    rm -rf /tmp/gh
                `,
          { stdio: "inherit" },
        );
        return true;
      } catch {
        return false;
      }
    });

    // OpenSSL - basic package manager install
    this.registerInstaller("openssl", async () => {
      return this.installPackage("openssl");
    });

    // Git LFS - basic package manager install
    this.registerInstaller("git-lfs", async () => {
      return this.installPackage("git-lfs");
    });
  }

  async installDependencies() {
    if (!this.isLinux()) {
      this.log(
        COLORS.YELLOW,
        "Cannot install system dependencies (not on Linux)",
      );
      return false;
    }

    if (this.distro === "unknown") {
      this.log(COLORS.RED, "Unsupported Linux distribution");
      return false;
    }

    const deps = PKG.systemDependencies || [];
    const missing = deps.filter((dep) => !this.commandExists(dep));

    if (missing.length === 0) {
      this.log(COLORS.GREEN, "All dependencies already installed");
      return true;
    }

    this.log(
      COLORS.BLUE,
      `Installing missing dependencies: ${missing.join(", ")}`,
    );

    // Update package list first
    await this.updatePackageList();

    let allSuccess = true;
    for (const dep of missing) {
      const installer = this.installers.get(dep);
      if (installer) {
        this.log(COLORS.BLUE, `Installing ${dep}...`);
        const success = await installer();
        if (success) {
          this.log(COLORS.GREEN, `✓ ${dep} installed`);
        } else {
          this.log(COLORS.RED, `✗ Failed to install ${dep}`);
          allSuccess = false;
        }
      } else {
        this.log(
          COLORS.YELLOW,
          `No installer defined for ${dep}, trying package manager...`,
        );
        const success = await this.installPackage(dep);
        if (!success) {
          this.log(COLORS.RED, `✗ Failed to install ${dep}`);
          allSuccess = false;
        }
      }
    }

    return allSuccess;
  }

  async promptInstall() {
    return new Promise((resolve) => {
      const readline = require("readline").createInterface({
        input: process.stdin,
        output: process.stdout,
      });

      readline.question(
        `${COLORS.YELLOW}Install missing system dependencies? [y/N]: ${COLORS.NC}`,
        (answer) => {
          readline.close();
          resolve(
            answer.toLowerCase() === "y" || answer.toLowerCase() === "yes",
          );
        },
      );
    });
  }

  async run() {
    this.log(COLORS.BLUE, "=== @diseec/kit System Dependencies ===");

    // Use the bash script for checking
    const checkScript = path.join(
      __dirname,
      "../src/informs/check-system-dependencies.sh",
    );
    try {
      execSync(`chmod +x "${checkScript}"`, { stdio: "ignore" });
      execSync(`"${checkScript}" check`, { stdio: "inherit" });
      this.log(COLORS.GREEN, "All dependencies are installed!");
      return;
    } catch (error) {
      // Dependencies are missing, continue with installation prompt
    }

    this.log(COLORS.YELLOW, "\nSome system dependencies are missing.");

    // In non-interactive environments (CI/CD), just warn
    if (!process.stdout.isTTY) {
      this.log(COLORS.YELLOW, "Run: npm run check-deps install");
      return;
    }

    const shouldInstall = await this.promptInstall();

    if (shouldInstall) {
      const installed = await this.installDependencies();
      if (!installed) {
        process.exit(1);
      }
    } else {
      this.log(
        COLORS.YELLOW,
        "You can install them later with: npm run check-deps install",
      );
    }
  }
}

// CLI interface
const command = process.argv[2];
const manager = new SystemDependencyManager();

switch (command) {
  case "install":
    manager.installDependencies().then((success) => {
      process.exit(success ? 0 : 1);
    });
    break;
  case "interactive":
  default:
    manager.run().catch((error) => {
      console.error(error);
      process.exit(1);
    });
    break;
}
