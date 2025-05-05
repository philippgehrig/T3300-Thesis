# T3000 Bachelor Thesis: Development of a PoC for a PCIe based Automotive Zonal Architecture

## Prerequisites

Before building the project, ensure you have the necessary tools installed.

### macOS

Install MacTeX using Homebrew:

```sh
brew install --cask mactex
```

### Linux (Debian-based)

Install TeX Live and latexmk:

```sh
sudo apt update && sudo apt install texlive-full latexmk
```

### Windows

1. Download and install [MiKTeX](https://miktex.org/download) or [TeX Live](https://tug.org/texlive/).
2. Ensure `latexmk` is installed and available in your PATH.

## Building the Project

Once the prerequisites are installed, navigate to the project directory and run:

```sh
latexmk -pdf master.tex
```

This will compile `master.tex` into a PDF document, handling dependencies automatically.

### Continuous Compilation

To enable automatic re-compilation on file changes, use:

```sh
latexmk -pdf -pvc master.tex
```

### Cleaning Auxiliary Files

To remove auxiliary files generated during compilation, run:

```sh
latexmk -c
```

## File Structure

```
📁 T3-3101-Studienarbeit/
 ├── 📄 master.tex       # Main LaTeX document
 ├── 📄 config.tex       # Configurations for project e.g. Title etc.
 ├── 📁 frontmatter/     # Frontmatter files (e.g., abstract, acknowledgments, ewerkl, acronyms, nondisclosurenotice)
 ├── 📁 chapters/        # Chapter files (e.g., introduction, chapter1, chapter2, chapter3, conclusion)
 ├── 📁 citations/       # Contains .pdf files of cited documents
 ├── 📁 appendix/        # Appendix files (e.g., appendix1, appendix2)
 ├── 📁 img/             # Images and figures
 ├── 📁 bibliography.bib # Bibliography Sources
 └── 📄 README.md        # This README file
```

## Troubleshooting

- Ensure that `latexmk` is installed and available in your PATH.
- If you encounter missing packages, use `tlmgr install <package-name>` (TeX Live) or `MiKTeX Console` to install them.
- If the PDF output is not updating, try running `latexmk -C` to force a full rebuild.


