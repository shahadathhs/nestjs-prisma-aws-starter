import { chalkStderr as chalk } from 'chalk';
import { emojify as emoji } from 'node-emoji';
import { execSync } from 'node:child_process';
import { default as yoctoSpinner } from 'yocto-spinner';

// Helper function to run shell commands and return the output
function runCommand(command) {
  try {
    console.info(chalk.blue(`Running command: ${command}`));
    return execSync(command, { encoding: 'utf-8' });
  } catch (error) {
    console.error(chalk.red(`Error while executing command: ${command}`));
    return error.message;
  }
}

// Get the list of staged files that are added or modified
function getStagedFiles() {
  const result = runCommand('git diff --cached --name-only');
  return result.split('\n').filter((file) => file);
}

// Commit changes with a given message
function autoCommit(message) {
  try {
    runCommand('git add .'); // stage all changes (lint/format fixes)
    runCommand(`git commit -m "${message}"`);
    console.info(chalk.green(emoji('✅') + ` Auto-commit done: "${message}"`));
  } catch (error) {
    console.error(chalk.red(emoji('❌') + ' Auto-commit failed.'));
    console.error(chalk.red(error));
  }
}

(async () => {
  const spinner = yoctoSpinner().start('Running CI checks on staged files...');

  const stagedFiles = getStagedFiles();

  if (stagedFiles.length === 0) {
    console.info(chalk.yellow(emoji('⚠️') + ' No staged files to check.'));
    spinner.stop();
    return;
  }

  // Select file groups
  const lintFiles = stagedFiles.filter(
    (file) =>
      file.endsWith('.js') ||
      file.endsWith('.ts') ||
      file.endsWith('.jsx') ||
      file.endsWith('.tsx'),
  );

  const formatFiles = stagedFiles.filter(
    (file) =>
      file.endsWith('.js') ||
      file.endsWith('.ts') ||
      file.endsWith('.json') ||
      file.endsWith('.jsx') ||
      file.endsWith('.tsx'),
  );

  let lintChangesApplied = false;
  let formatChangesApplied = false;

  try {
    if (lintFiles.length > 0) {
      spinner.start('Running lint check...');
      const lintResult = runCommand(`pnpm lint -- ${lintFiles.join(' ')}`);
      spinner.success(chalk.green(emoji('✅') + ' Lint checks passed!'));

      spinner.start('Applying lint fixes...');
      const fixResult = runCommand(`pnpm lint:fix -- ${lintFiles.join(' ')}`);
      spinner.success(chalk.green(emoji('⚙️') + ' Lint fixes applied!'));
      lintChangesApplied = true;

      console.info(
        chalk.blue(emoji('💻') + ' Lint output:\n') + chalk.gray(lintResult),
      );
      console.info(
        chalk.blue(emoji('🔧') + ' Fix output:\n') + chalk.gray(fixResult),
      );
    }

    if (lintChangesApplied) {
      spinner.start('Staging lint fixes...');
      runCommand('git add .');
      spinner.success(chalk.green(emoji('✅') + ' Lint fixes staged!'));
    }

    if (formatFiles.length > 0) {
      spinner.start('Running format check...');
      const formatResult = runCommand(
        `pnpm format -- ${formatFiles.join(' ')}`,
      );
      spinner.success(chalk.green(emoji('✅') + ' Format checks passed!'));

      spinner.start('Applying format fixes...');
      const formatFixResult = runCommand(
        `pnpm format:fix -- ${formatFiles.join(' ')}`,
      );
      spinner.success(chalk.green(emoji('⚙️') + ' Format fixes applied!'));
      formatChangesApplied = true;

      console.info(
        chalk.blue(emoji('📝') + ' Format output:\n') +
          chalk.gray(formatResult),
      );
      console.info(
        chalk.blue(emoji('🔧') + ' Format fix output:\n') +
          chalk.gray(formatFixResult),
      );
    }

    if (formatChangesApplied) {
      spinner.start('Staging format fixes...');
      runCommand('git add .');
      spinner.success(chalk.green(emoji('✅') + ' Format fixes staged!'));
    }

    spinner.success(chalk.cyan(emoji('🚀') + ' All checks & fixes completed!'));
  } catch (error) {
    spinner.error(chalk.red(emoji('❌') + ' An error occurred.'));
    console.error(chalk.red(error));
  }
})();
