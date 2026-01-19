#!/usr/bin/env node

import meow from "meow";
import ora from "ora";
import chalk from "chalk";
import fs from "fs/promises";
import path from "path";
import { filesize as formatFileSize } from "filesize";
import { isBinaryFile } from "isbinaryfile";

// const execAsync = promisify(exec);

const IMAGE_EXTENSIONS = [
  ".jpg",
  ".jpeg",
  ".png",
  ".gif",
  ".bmp",
  ".svg",
  ".svg~",
  ".webp",
  ".tiff",
];

const IGNORE = [
  "node_modules",
  ".git",
  ".env",
  ".venv",
  "__pycache__",
  ".gitignore",
  "package-lock.json",
  "package.json",
  "output.txt",
];

const helpText = `
  ${chalk.bold("Usage")}
    $ git2txt <repository-url>

  ${chalk.bold("Options")}
    --output, -o     Specify output file path
    --threshold, -t  Set file size threshold in MB (default: 0.5)
    --include-all    Include all files regardless of size or type
    --debug         Enable debug mode with verbose logging
    --help          Show help
    --version       Show version

  ${chalk.bold("Examples")}
    $ git2txt https://github.com/username/repository
    $ git2txt https://github.com/username/repository --output=output.txt
`;

export const cli = meow(helpText, {
  importMeta: import.meta,
  flags: {
    output: {
      type: "string",
      shortFlag: "o",
    },
    threshold: {
      type: "number",
      shortFlag: "t",
      default: 0.1,
    },
    includeAll: {
      type: "boolean",
      default: false,
    },
    debug: {
      type: "boolean",
      default: false,
    },
  },
});

function formatSize(bytes) {
  const sizes = ["o", "Ko", "Mo", "Go", "To"];
  if (bytes === 0) return "0o";
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${(bytes / Math.pow(1024, i)).toFixed(2)} ${sizes[i]}`;
}

async function processTree(directory, indent = "") {
  try {
    const files = await fs.readdir(directory, { withFileTypes: true });

    for (const file of files) {
      const filePath = path.join(directory, file.name);

      if (file.isDirectory()) {
        if (IGNORE.includes(file.name) || file.name.endsWith(".egg-info")) {
          console.log(chalk.red(`${indent}📂 ${file.name}`));
          continue;
        }
        console.log(chalk.green(`${indent}📂 ${file.name}`));
        await processTree(filePath, indent + "   ");
        continue;
      }

      if (!file.isFile()) continue;

      const fileExtension = path.extname(file.name).toLowerCase();

      // Skip image files
      // if (IMAGE_EXTENSIONS.includes(fileExtension)) {
      //   continue;
      // }

      const stats = await fs.stat(filePath);
      const fileSize = formatSize(stats.size);

      if (
        IGNORE.includes(file.name) ||
        IMAGE_EXTENSIONS.includes(fileExtension)
      ) {
        if (file.name === "output.txt") {
          console.log(chalk.blueBright(`${indent}🤖 ${file.name}     (${fileSize})`));
        } else {
          console.log(chalk.red(`${indent}📄 ${file.name}     (${fileSize})`));
        }
        continue;
      }
      console.log(chalk.yellow(`${indent}📄 ${file.name}     (${fileSize})`));
    }
  } catch (error) {
    console.error(chalk.red(`Erreur : ${error.message}`));
  }
}

export async function processFiles(directory, options) {
  let spinner =
    process.env.NODE_ENV !== "test" ? ora("Processing files...").start() : null;
  const thresholdBytes = options.threshold * 1024 * 1024;
  let output = "";
  let processedFiles = 0;
  let skippedFiles = 0;

  const skippedExtensions = new Set();
  const processedExtensions = new Set();

  /**
   * Recursively processes files in a directory
   * @param {string} dir - Directory to process
   */
  async function processDirectory(dir) {
    const entries = await fs.readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);

      if (
        entry.isDirectory() && !IGNORE.includes(entry.name) &&
        !entry.name.endsWith(".egg-info")
      ) {
        // Recursively process subdirectories
        await processDirectory(fullPath);
        continue;
      }

      if (IGNORE.includes(entry.name)) {
        skippedFiles++;
        continue;
      }

      if (!entry.isFile()) continue;

      const fileExtension = path.extname(entry.name).toLowerCase();

      // Skip image files
      if (IMAGE_EXTENSIONS.includes(fileExtension)) {
        skippedExtensions.add(fileExtension);
        if (process.env.DEBUG) {
          console.log(`Skipping image file: ${entry.name}`);
        }
        skippedFiles++;
        continue;
      }

      try {
        const stats = await fs.stat(fullPath);

        // Skip if file is too large and we're not including all files
        if (!options.includeAll && stats.size > thresholdBytes) {
          skippedExtensions.add(fileExtension);
          if (process.env.DEBUG)
            console.log(`Skipping large file: ${entry.name}`);
          skippedFiles++;
          continue;
        }

        // Skip binary files unless includeAll is true
        if (!options.includeAll) {
          if (await isBinaryFile(fullPath)) {
            skippedExtensions.add(fileExtension);
            if (process.env.DEBUG)
              console.log(`Skipping binary file: ${entry.name}`);
            skippedFiles++;
            continue;
          }
        }

        processedExtensions.add(fileExtension !== "" ? fileExtension : "' '");

        const content = await fs.readFile(fullPath, "utf8");
        const relativePath = path.relative(directory, fullPath);

        output += `\n${"=".repeat(80)}\n`;
        output += `File: ${relativePath}\n`;
        output += `Size: ${formatFileSize(stats.size)}\n`;
        output += `${"=".repeat(80)}\n\n`;
        output += `${content}\n`;

        processedFiles++;

        if (process.env.DEBUG) {
          console.log(`Processed file: ${relativePath}`);
        }
      } catch (error) {
        if (process.env.DEBUG) {
          console.error(`Error processing ${entry.name}:`, error);
        }
        skippedFiles++;
      }
    }
  }

  try {
    // Process the entire directory tree
    await processDirectory(directory);

    if (spinner) {
      spinner.succeed(
        `Processed ${processedFiles} files successfully (${skippedFiles} skipped)`
      );
    }

    if (processedFiles === 0 && process.env.DEBUG) {
      console.warn("Warning: No files were processed");
    }

    console.log("\nSummary of Extensions:");
    console.log("Skipped Extensions:", Array.from(skippedExtensions).join(" "));
    console.log(
      "Processed Extensions:",
      Array.from(processedExtensions).join(" ")
    );

    return output;
  } catch (error) {
    if (spinner) {
      spinner.fail("Failed to process files");
    }
    throw error;
  }
}

/**
 * Writes the processed content to an output file
 * @param {string} content - Content to write
 * @param {string} outputPath - Path to the output file
 * @returns {Promise<void>}
 * @throws {Error} If writing fails
 */
export async function writeOutput(content, outputPath) {
  let spinner =
    process.env.NODE_ENV !== "test"
      ? ora("Writing output file...").start()
      : null;

  try {
    await fs.writeFile(outputPath, content);
    if (spinner) spinner.succeed(`Output saved to ${chalk.green(outputPath)}`);
  } catch (error) {
    if (spinner) spinner.fail("Failed to write output file");
    if (process.env.NODE_ENV !== "test") {
      console.error(chalk.red("Write error:"), error);
    }
    throw error;
  }
}

/**
 * Cleans up temporary files and directories
 * @param {string} directory - Directory to clean up
 * @returns {Promise<void>}
 */
export async function cleanup(directory) {
  try {
    await fs.rm(directory, { recursive: true, force: true });
  } catch (error) {
    if (process.env.NODE_ENV !== "test") {
      console.error(
        chalk.yellow("Warning: Failed to clean up temporary files")
      );
    }
  }
}

/**
 * Main application function that orchestrates the entire process
 * @returns {Promise<void>}
 */
export async function main() {
  let tempDir;
  try {
    // const url = await validateInput(cli.input);
    if (process.env.NODE_ENV !== "test") {
      // const result = await downloadRepository(url);
      // tempDir = result.tempDir;

      console.log("\n");
      await processTree(".");
      console.log("\n");

      const outputPath = cli.flags.output || `output.txt`;
      const content = await processFiles(".", {
        threshold: cli.flags.threshold,
        includeAll: cli.flags.includeAll,
      });

      if (!content) {
        throw new Error("No content was generated from the folder");
      }

      await writeOutput(content, outputPath);
    }
  } catch (error) {
    if (process.env.NODE_ENV === "test") {
      throw error;
    } else {
      console.error(chalk.red("\nAn unexpected error occurred:"));
      console.error(error.message || error);
      exit(1);
    }
  } finally {
    if (tempDir) {
      await cleanup(tempDir);
    }
  }
}

// Only run main if not in test environment
if (process.env.NODE_ENV !== "test") {
  main();
}
