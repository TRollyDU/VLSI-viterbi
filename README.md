# RTL hiện hành: shared_control + PISO14 mask + optional input handshake

Yêu cầu nằm ở đầu [README gốc](../README.md): đúng 1.025 cặp file, ZERO_TAIL=1,
PM lưu 2 bit, timing 3,2 ns/312,5 MHz. Người dùng đã chọn `handshake_off` với
**E17/II19**, thay cho prefix LUT E15/II17.

## Các module

- `top.v`: nối các khối và chứa BM pipeline. BM FF đọc cặp PISO cũ trước cạnh
  shift, giữ đúng toán hạng cho hai pha COMPARE / SELECT+ADD.
- `input_handshake.v`: ENABLE=0 mặc định bỏ toàn bộ busy/ready FF, accept=in_valid,
  in_ready=1. Bên ngoài phải phát pulse start một clock và chờ output transfer.
  ENABLE=1 giữ một frame outstanding, R1/R2 startup, queued valid/backpressure.
  Top chọn qua INPUT_HANDSHAKE, instance handshake_ins.
- `controller.v`: nhận accept, sinh phase/control/PISO one-hot. pm_write_en là
  alias của FF step_en; init PMU có ưu tiên nên không cần xung write E1 riêng.
- `piso14_7.v`: giữ cặp 2–8, nhận codeword_in[13:0]. Shift E2/E4/…/E12,
  preload từ E14. load_data, shifted_data, held_data chỉ đóng góp khi operation
  tương ứng bật; OR kết hợp chúng. Control phải one-hot, có assertion kiểm tra.
- `bmu.v`: tổ hợp, bốn Hamming distance 0..2 trước BM FF ở top.
- `pmu.v`: E0 chốt first_pair_in; E1 khởi tạo PM0/PM2 từ cặp đầu. Init ưu tiên,
  sau đó chỉ ghi low2 survivor khi pm_write_en=1, còn lại giữ PM. Không còn LUT.
- `acs.v`: hai butterfly_pm2, select_q, decisions_q và bốn survivor adder.
  first_step ép select_q=0 ở bước 2; các bước sau dùng butterfly bình thường.
  Xuất trực tiếp next_s0..3, không có enable ghi hay mux giữ PM.
- `rex.v`: module rex, instance rex_ins; history sáu bit/state và suffix cố định.
  Sáu update cuối xóa history cũ, kể cả sau reset/restart.
- `output_register.v`: valid giữ đến transfer; REGISTER_DATA chọn chốt data
  hoặc nối history. Top truyền OUTPUT_REGISTER.
- `psu.v`: khi ZERO_TAIL=0, chọn endpoint rồi dùng output_register. Controller
  hiện tại cấp final_re_en tại E16 và output_en tại E17.

## Khởi tạo tuần tự thay prefix LUT

Encoder bắt đầu từ S0. Sau cặp received đầu r1, chỉ S0/S2 tới được:

```text
PM0 = Hamming(r1, 00)
PM2 = Hamming(r1, 11)
```

PM1/PM3 tại E1 là placeholder 0, không phải vô cực; không được dùng chúng làm
predecessor hợp lệ. E2 ép cả bốn select về A: PM0 cho S0/S2, PM2 cho S1/S3.
E3 dùng bốn adder đang có, với cặp thứ hai r2:

```text
PM0_mới = PM0 + Hamming(r2, 00)
PM2_mới = PM0 + Hamming(r2, 11)
PM1_mới = PM2 + Hamming(r2, 10)
PM3_mới = PM2 + Hamming(r2, 01)
```

Bốn kết quả là khoảng cách tới prefix dự kiến 0000, 1110, 0011, 1101 như LUT cũ.
PM lưu low2 nên distance 4 lưu thành 0; không chọn cứng state thắng hay chuẩn hóa.
Test đủ 16 prefix đối chiếu với encoder độc lập. Input có thể đổi sau E0 vì đã
chốt cả cặp đầu và bảy cặp còn lại.

## Số học và lịch

Distance bù là d và 2−d, d=0..2. Với unsigned PM2 A/B:
N0=min(A+d,B+2−d), N1=min(A+2−d,B+d); hòa chọn A.
butterfly_pm2.v giải thích ngưỡng. add_hamming dùng phép cộng thông thường
`{1'b0, pm} + {1'b0, bm}` giữ đủ 3 bit. Function Boolean cũ nằm trong comment
để thử thủ công, không có parameter/define chọn cách cộng.

E0 accept, E1 init. E2/E4/…/E14 chốt select_q; riêng E2 ép A.
E3/E5/…/E15 chọn+cộng, ghi PM và chuyển decision tới REX.
REX E4/E6/…/E16; output E17, transfer E18, input mới E19 (II19).
PISO shift E2/E4/…/E12; BM cặp 8 chốt E13, preload từ E14.

OUTPUT_REGISTER=1 mặc định chốt data tại E17, giữ cả khi invalid và reset về 0.
Đặt 0 để nối history: valid vẫn là FF, data ổn định khi valid nhưng không quy
định khi invalid/reset. Hai option giữ E17/II19, hỗ trợ ZERO_TAIL=0/1.
PPA mặc định là 76 FF; bypass chưa đo P&R riêng cho kiến trúc này.

## Kiểm chứng và số đo

`.\tb\run_tests.ps1 -RunName selected_control_options_20261022`: **15 Vivado benches PASS**.
Mode protected và raw-start, 1.025 vector, hai option output, PSU, E17/II19 theo
lịch driver, reset/restart và output hold. Formal ENABLE=1 khớp RTL cũ ZERO_TAIL=0/1.
Default INPUT_HANDSHAKE=0 không có busy protection; in_ready luôn 1 kể cả reset.

P&R default: 76 FF, area 4534,35 µm², setup +0,167118 ns, hold +0,096095 ns,
hold r2r +0,156547 ns tại 3,2 ns/312,5 MHz. Power default activity TT 2,614717 mW,
không coi là năng lượng workload. Khi INPUT_HANDSHAKE=1: 78 FF, cũng PASS 3,2 ns.
PISO hold NOR thử riêng 75 FF, setup +0,119705 ns, hold +0,099278 ns;
root vẫn giữ FF hold. Không có ECO netlist/cell/ODB hay thay SDC/margins.

[Source/hash/verification/PPA](../result/control_options_20261022/README.md).
