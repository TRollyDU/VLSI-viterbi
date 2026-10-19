# RTL hiện hành — PM2, 1.025 vector, Fmax mong muốn 350 MHz

**Yêu cầu có hiệu lực nằm ở đầu [README gốc](../README.md): chỉ nghiệm thu
1.025 cặp input.txt/output.txt ở ZERO_TAIL=1; PM lưu 2 bit; Fmax mong muốn
350 MHz (period khoảng 2,857143 ns), còn yêu cầu đạt timing chỉ tại chu kỳ
3,2 ns (312,5 MHz).** Không dùng exhaustive ML ngoài bộ file để
tự quay lại PM3. Quyết định này được ghi ngày 19/10/2026 theo yêu cầu người dùng.

**Định hướng thiết kế: Fmax cao và power thấp; area được theo dõi để cân nhắc
đánh đổi.**

Datapath hard-decision K=3, rate=1/2, generator (7,5), tám received pairs,
state đầu S0. Cặp đầu codeword_in[15:14], cặp cuối [1:0].

- `top.v`: handshake một giao dịch, FF ready/busy, FF BM/decision và output.
  ZERO_TAIL=1 mặc định lấy history S0, không có instance PSU.
- `pmu.v`: E0 chốt prefix partial; E1 tạo PM sau hai bước. Bốn thanh ghi PM
  **2 bit**, giữ low bits theo modulo 4; input từ ACS vẫn 3 bit. Không có
  global normalization hoặc saturation chung. Complement distance dùng logic
  chuyên biệt trên miền Hamming 0..2.
- `acs.v`: PM đầu vào **2 bit**, BM 2 bit; FF candidate `sum_A/sum_B` **3 bit**.
  Candidate thuộc 0..5. Min trực tiếp từng bit, decision strict `>` chọn B;
  hòa chọn A. Output candidate-selected metric 3 bit trước khi PMU lưu low2.
- `piso12_6.v`: chốt codeword_in[11:0], output [11:10] đi thẳng BMU.
  Nhận ba FF one-hot load/shift/hold từ controller; chọn dữ liệu bằng AND/OR,
  không có local hold decode hoặc priority mux. Dịch E2/E4/E6/E8/E10; preload
  lại từ E12 sau khi BM8 đã được chốt E11. Input vẫn được chốt đúng E0.
- `bmu.v`: bốn Hamming distances 0..2, top chốt trước mỗi ADD hợp lệ.
- `reg_ex.v`: bốn history, sáu FF bit/state; suffix hai bit lấy từ state.
  RE cập nhật theo marker trễ một clock từ SELECT.
- `controller.v`: E1 init, ADD E2/E4/.../E12, SELECT E3/E5/.../E13,
  RE cuối E14, output E15. Thêm ba FF piso_load/piso_shift/piso_hold,
  tính trước pha; không trễ thêm một clock. Reset chọn load=1, shift=hold=0.
- `psu.v`: parameter ZERO_TAIL=0 tạo instance chọn endpoint bằng bốn PM2;
  chốt state E14 và output E15. Nghiệm thu file dùng ZERO_TAIL=1.

**Latency E15, transfer sớm nhất E16, II=17.** Backpressure giữ valid/data;
FF ready chỉ mở sau khi giao output. Reset bất đồng bộ active-low hủy giao dịch,
xóa output/ready. R1 sau nhả reset chỉ nâng ready; R2 mới nhận input.

`config.json`, `viterbi_pnr.sdc`, `viterbi.sdc` thống nhất clock nghiệm thu timing
**3,2 ns / 312,5 MHz**; Fmax mong muốn vẫn là **350 MHz**. Các ràng buộc I/O, uncertainty và derating
giữ nguyên. Config chỉ tổng hợp tám file thiết kế, không tổng hợp tb_top.v.

Chạy từ root:

```powershell
.\tb\run_tests.ps1 -RunName piso_registered_control_20261019
```

[Báo cáo và số liệu sau route](../result/piso_registered_control_20261019/README.md),
[file test](../sim/piso_registered_control_20261019/tb_top.log),
[stream/protocol test](../sim/piso_registered_control_20261019/tb_vector_contract.log).
Snapshot PM3 và testbench trước thay đổi được giữ trong
`../result/pm2_vectors_350mhz_20261019/before_pm2/`.

Kết quả sau route của lần chạy đã lưu ở **350 MHz: đạt**, setup +0,000961 ns,
hold +0,103358 ns, area 5.318,85 µm², 96 FF; không ECO thủ công. Biên setup
khoảng 0,96 ps; đường găng trong lần chạy đó là FF in_ready ra cổng.
Snapshot và báo cáo giữ constraint 350 MHz để tái lập kết quả. Config/SDC hiện tại
đã chuyển về 3,2 ns; chưa chạy lại P&R/STA theo mốc này.
