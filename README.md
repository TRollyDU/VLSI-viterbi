# VLSI-viterbi
viterbi decode for ppa ranking

## Cách commit
##  Cách 1: Nộp bằng website GitHub (không cần cài Git)

### A. Nếu bạn có quyền Write trong repo

1. Đăng nhập GitHub và mở repository do người quản lý cung cấp.
2. Bấm vào **thư mục bài** (ví dụ `14_rca4/`).
3. Bấm **Add file → Upload files**; kéo thả **ba file** `spec.txt`, `rca4.v` và `tb_rca4.v` vào trang. Đảm bảo đang upload ở **đường dẫn `14_rca4/`**.
4. Nhập commit message, ví dụ `Add exercise 14 ripple-carry adder`.
5. Chọn **Create a new branch for this commit and start a pull request** thay vì commit thẳng vào `main`. Đặt branch ví dụ `submit-14-rca4`.
6. Bấm **Propose changes**, tiếp theo **Create pull request** (tên nút có thể thay đổi nhẹ).
7. **Xóa `.gitkeep` trên cùng branch**: mở file `.gitkeep` trong branch vừa tạo, chọn menu xóa file, commit thay đổi vào branch đó. PR tự cập nhật. Nếu thao tác này khó, nhờ người quản lý xóa `.gitkeep` khi duyệt PR.
8. Điền PR mô tả các đầu vào/đầu ra, cách kiểm tra và gửi cho người quản lý review.

### B. Nếu bạn KHÔNG có quyền Write trong repo

1. Mở repo gốc → bấm **Fork** để tạo bản sao repo trong tài khoản của bạn.
2. Vào fork của bạn và làm lại các thao tác upload trong mục A (chọn branch riêng trong fork).
3. Mở PR về repo gốc: bấm **Contribute → Open pull request** hoặc **Compare & pull request**.
4. Kiểm tra **base** là `main` của repo gốc, **compare/head** là branch trong fork của bạn rồi tạo PR.
5. Người quản lý repo gốc sẽ review và merge. Bạn không cần quyền Write vào repo gốc.

**Sửa file đã có:** vào đúng file, dùng biểu tượng chỉnh sửa (bút chì); commit thay đổi vào branch đang nộp. Nên giữ mỗi bài trong cùng một PR.

## 4. Cách 2: Nộp bằng Git Bash / Terminal (biết `add`, `commit`, `push`)

**Chuẩn bị:** cài Git. Nếu repo gốc cấp quyền Write thì clone repo gốc. Nếu không có Write, trên GitHub **Fork repo trước**, rồi clone URL của fork của chính bạn.

```bash
# Chỉ làm lần đầu: tải repo về máy (thay đường dẫn của repo mà bạn được phép push)
git clone https://github.com/YOUR_USERNAME/rtl-verilog-35-exercises.git
cd rtl-verilog-35-exercises

# Tạo branch mới từ main cập nhật
git switch main
git pull origin main
git switch -c submit-14-rca4
```

Giờ mở thư mục `14_rca4/` trên máy và thêm `spec.txt`, `rca4.v`, `tb_rca4.v`, xóa `.gitkeep`. Rồi chạy:

```bash
git status                       # Xem file mới, file thay đổi, file đã xóa
git add 14_rca4/                 # Stage tất cả thay đổi trong bài 14, gồm xóa .gitkeep
git status                       # Kiểm tra lại trước khi commit
git commit -m "Add exercise 14 RCA 4-bit"
git push -u origin submit-14-rca4
```

Cuối cùng, mở link repo trên GitHub → **Compare & pull request** → mô tả rồi bấm **Create pull request**.

**Các lệnh thường dùng:**

| Lệnh | Ý nghĩa |
|---|---|
| `git status` | Xem file đã đổi và đang ở branch nào |
| `git pull origin main` | Lấy cập nhật mới nhất của nhánh main về máy (khi đang đứng ở main) |
| `git switch -c ten-branch` | Tạo và chuyển sang branch riêng |
| `git add 14_rca4/` | Chọn toàn bộ thay đổi của thư mục bài 14 |
| `git commit -m "Noi dung"` | Lưu thay đổi thành một commit |
| `git push -u origin ten-branch` | Gửi branch lên GitHub |
| `git log --oneline -5` | Xem 5 commit gần nhất |

**Nếu bị `Permission denied` khi push:** bạn không có quyền với repo gốc hoặc chưa đăng nhập; hãy dùng fork của mình và push lên fork (kiểm tra `git remote -v`).

**Nếu `git commit` báo `nothing to commit`:** chưa thay đổi file, hoặc đang đứng sai thư mục, hoặc đã commit những thay đổi đó rồi. Chạy `git status`.

**Nếu `git push` báo `rejected` / `non-fast-forward`:** có cập nhật mới trên branch ở GitHub. Đừng dùng `--force`; xem lại branch, fetch/pull và xử lý conflict hoặc hỏi người quản lý.

## 5. Người quản lý: Review và merge

1. Vào tab **Pull requests** của repository.
2. Mở PR, xem tab **Files changed**.
3. Xác minh chỉ một thư mục bài được cập nhật; đã có `spec.txt`, RTL và testbench đúng tên; đã xóa `.gitkeep`; `spec.txt` nêu đủ chức năng, I/O.
4. Nếu ổn, chọn **Merge pull request**. Nếu chưa ổn, comment để người nộp chỉnh sửa trên branch cũ.
5. Sau merge, thư mục trên `main` sẽ có đúng ba file bài tập. Không cần tạo thư mục khác.
