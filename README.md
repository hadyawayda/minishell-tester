# Minishell Tester

### 1. Prerequisites

#### Have Python installed (for the excel to csv files conversion)

### 2. Install required packages

#### Update local packages (WSL Users Only)

```bash
sudo apt-get update
sudo apt install make
sudo apt install gcc -y
sudo apt install libreadline-dev
```

#### For windows users only (if getting \r errors)

```bash
sed -i 's/\r$//' tester.sh
```

### 3. Install dependencies

```bash
sudo apt install csvkit -y
```

#### or if sudo access not available:

```bash
pip install csvkit
echo 'export PATH="$PATH:/home/$USER/.local/bin"' >> ~/.zshrc
source ~/.zshrc
```

### 4. Run tester

```bash
cd tester
./tester.sh
```
