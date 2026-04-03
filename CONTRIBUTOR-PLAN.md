# Kế hoạch: Trở thành Contributor của hl-tutor

## Mục tiêu
Trở thành contributor cho https://github.com/hungson175/hl-tutor

---

## Bước 1: Fork & Clone Repository

### 1.1 Fork trên GitHub
1. Mở https://github.com/hungson175/hl-tutor
2. Click **Fork** (góc trên bên phải)
3. Tạo fork vào tài khoản GitHub của bạn

### 1.2 Clone về máy (trong WSL Ubuntu)
```bash
# Clone fork của bạn
git clone https://github.com/[YOUR_GITHUB_USERNAME]/hl-tutor.git ~/hl-tutor

# Di chuyển vào thư mục
cd ~/hl-tutor

# Thêm upstream remote để sync với repo gốc
git remote add upstream https://github.com/hungson175/hl-tutor.git

# Kiểm tra remotes
git remote -v
```
**Output mong đợi:**
```
origin    https://github.com/YOUR_USERNAME/hl-tutor.git (fetch)
origin    https://github.com/YOUR_USERNAME/hl-tutor.git (push)
upstream  https://github.com/hungson175/hl-tutor.git (fetch)
upstream  https://github.com/hungson175/hl-tutor.git (push)
```

---

## Bước 2: Cài đặt Development Environment

```bash
# Cài đặt dependencies
bash <(curl -fsSL https://raw.githubusercontent.com/hungson175/hl-tutor/main/setup.sh)

# Verify Claude Code hoạt động
claude --version
```

---

## Bước 3: Tìm Issues để Contrib

### 3.1 Issues đã biết (từ testing của bạn)
Bạn đã tìm ra 3 issues trong quá trình dùng thực tế:
1. **Tutor không nhận diện WSL/Linux** — cần fix environment detection
2. **User phải gõ `claude` thủ công** — cần auto-start
3. **Copy-paste khó khăn** — cần UI improvement

### 3.2 Tìm thêm issues
1. Mở https://github.com/hungson175/hl-tutor/issues
2. Filter: `good first issue` hoặc `help wanted`
3. Hoặc tự tìm bugs bằng cách dùng thử

### 3.3 Chọn Issue để fix
**Khuyến nghị bắt đầu với:**
- Issue #1 (environment detection) — vì bạn đã hiểu rõ vấn đề

---

## Bước 4: Tạo Branch & Fix Issue

### 4.1 Tạo branch mới
```bash
cd ~/hl-tutor

# Đảm bảo branch sạch
git checkout main
git pull upstream main

# Tạo branch cho issue
git checkout -b fix/wsl-environment-detection
```

### 4.2 Code your fix
- Đọc code hiện tại để hiểu cách tutor detect environment
- Sửa code để detect WSL đúng
- Test trên máy của bạn

### 4.3 Commit với conventional commits
```bash
git add .
git commit -m "fix: detect WSL/Linux environment for correct command instructions"
```

---

## Bước 5: Submit Pull Request

### 5.1 Push lên fork
```bash
git push origin fix/wsl-environment-detection
```

### 5.2 Tạo Pull Request
1. Mở https://github.com/hungson175/hl-tutor
2. GitHub sẽ hiện "Compare & pull request"
3. Click **Create pull request**
4. Mô tả:
   - Issue nào bạn đang fix
   - Bạn đã thay đổi gì
   - Testing: đã test trên máy chưa, kết quả thế nào

### 5.3 Mẫu PR Description
```markdown
## Fixes Issue: [mô tả issue]

### Problem
Tutor không nhận diện được đang chạy trên WSL/Linux, đưa ra instructions cho macOS.

### Solution
Thêm detection cho WSL environment bằng cách check `/proc/version` hoặc `uname -a`.

### Testing
Đã test trên:
- Ubuntu 22.04 on WSL2 (Windows 11)
- macOS (để đảm bảo không break)
```

---

## Bước 6: Đợi Review & Merge

- Maintainer sẽ review code
- Có thể được yêu cầu thay đổi
- Sau khi approved → merged!

---

## Lộ trình Contributor

| Giai đoạn | Mục tiêu | Thời gian |
|-----------|----------|----------|
| **Tuần 1** | Fork, clone, hiểu codebase | 2-3 giờ |
| **Tuần 2** | Fix issue #1 (environment detection) | 3-4 giờ |
| **Tuần 3** | Submit PR đầu tiên, nhận feedback | 1-2 giờ |
| **Tuần 4** | Fix thêm issues, build reputation | 3-4 giờ/tuần |

---

## Checklist trước khi submit PR

- [ ] Đã test trên WSL Ubuntu
- [ ] Đã test trên macOS (nếu có máy)
- [ ] Code tuân thủ style của project
- [ ] Commit message rõ ràng
- [ ] Mô tả PR đầy đủ

---

## Tài liệu tham khảo

- GitHub Flow: https://docs.github.com/en/get-started/quickstart/github-flow
- How to Contribute: https://opensource.guide/how-to-contribute/
- Conventional Commits: https://www.conventionalcommits.org/
