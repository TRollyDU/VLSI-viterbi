# Đặc tả chức năng hiện hành

Ngày cập nhật: **2026-11-21**. Nguồn: yêu cầu và xác nhận trực tiếp của người dùng,
đối chiếu `requirement - functional_spec - Vplan - Viterbi.pdf`.

RTL và bộ 9 testbench SystemVerilog đã được chuyển sang hợp đồng này trong đợt
`smu_pulse_20261121`. Kết quả kiểm chứng/PPA của đợt mới được ghi riêng trong
`verification/`; các receipt cũ chỉ chứng minh revision được ghi trong receipt.

## 1. Mã hóa và giải mã

- Hard-decision Viterbi, K=3, rate 1/2, đa thức sinh (7,5):
  `x^2 + x + 1` và `x^2 + 1`.
- Mỗi frame độc lập bắt đầu tại S0 (trạng thái encoder `00`).
- **Mỗi frame chứa đủ 8 bit thông tin**, mã hóa thành 16 bit đầu vào.
- **Không bắt buộc tail `00`**. Hai bit cuối của dữ liệu gốc có thể là `00`,
  `01`, `10` hoặc `11`; đầu ra không bị ép `output_data[1:0] == 2'b00`.
- Xử lý cặp nhận từ MSB trước, giữ quy ước encoder của dự án.
- Sau tám bước trellis, PSU chọn endpoint có path metric nhỏ nhất trong
  S0/S1/S2/S3 và trả toàn bộ history 8 bit tương ứng.
- Không cố định endpoint S0. RE và PSU được gộp trong module **`smu`**.
- ACS tie chọn predecessor A; tie giữa các endpoint ưu tiên S0, S1, S2, S3.
  RTL và oracle cùng dùng thứ tự này.

“Mọi đầu vào” nghĩa là mỗi word nhận 16 bit đều có kết quả theo thuật toán và
quy tắc tie đã định nghĩa. Không có cam kết khôi phục đúng bản tin gốc dưới
mọi mẫu lỗi kênh không giới hạn.

## 2. Giao diện và giao dịch

Top đích là `viterbi_top`, với đúng các port sau:

| Port | Hướng | Độ rộng | Chức năng |
|---|---|---:|---|
| `clk` | Input | 1 | Clock cạnh lên |
| `rstn` | Input | 1 | Reset ngoài bất đồng bộ, active-low; đưa qua `r_sync` |
| `viterbi_enable` | Input | 1 | Xung một chu kỳ yêu cầu nhận frame khi idle |
| `input_data` | Input | 16 | Word nhận được chốt tại cạnh chấp nhận enable |
| `output_data` | Output | 8 | Toàn bộ 8 bit thông tin đã giải mã |
| `output_done` | Output | 1 | Xung một chu kỳ báo kết quả hợp lệ |

- Bỏ IU/OU khỏi đường tích hợp top; dùng `r_sync` xử lý reset ngoài.
- Chỉ có một frame đang xử lý, không nhận chồng hoặc lưu frame chờ.
- Sau khi nhận enable, bỏ qua mọi thay đổi input và mọi xung enable trong lúc
  busy. Chỉ mở nhận frame mới sau khi đã phát xung done của frame hiện tại.
- Không có giao diện valid/ready hoặc backpressure ở top mới.
- Reset hủy frame đang xử lý; không phát done cho frame đã bị hủy.

`r_sync` có cơ chế assert bất đồng bộ, release đồng bộ. Cách reset các thanh ghi
downstream là đồng bộ, qua FF `core_reset_n` được giữ lại. Chỉ hai FF trong
`r_sync` dùng reset bất đồng bộ. Start và done ở biên top bị chặn ngay khi
`reset_n` của `r_sync` thấp, ngăn done lọt trong thời gian reset lan vào core.
Giữ reset ngoài thấp qua ít nhất hai cạnh lên. Sau release, synchronizer nhả
sau R2, core sẵn sàng sau R3 và cạnh nhận frame sớm nhất là R4.

## 3. Lịch và datapath đã triển khai

- E0 nhận enable/input; E1-E8 cập nhật metric; E2-E9 cập nhật history; E10 chốt
  kết quả và phát done. E11 là cạnh nhận frame tiếp theo sớm nhất (II11).
- Output giữ ổn định giữa hai kết quả; không nhận enable tại chính cạnh E10
  tạo done. Các xung enable trong E1-E10 bị bỏ qua, không lưu chờ.
- PM3, ACS3, init `[0,4,4,4]` được giữ sau khi mô hình integer kiểm tra đủ
  65.536 word khớp oracle free-endpoint với unreachable thực sự. Candidate maxima
  theo bước là `[6,7,6,5,5,6,6,7]`; TB toàn mạng kiểm tra lại bằng phép cộng 4 bit.
- PMU và histories chỉ cập nhật theo enable, giữ dữ liệu cuối cho PSU tại E10.
  History không reset; tám RE update hợp lệ flush dữ liệu của frame trước.
- E10/II11 là kết quả chức năng theo clock mô phỏng, không phải chứng minh STA.

## 4. Tiêu chí kiểm chứng và PPA

- Oracle độc lập theo số nguyên, bắt đầu S0 và chọn min trên bốn endpoint.
- Kiểm tra đủ 65.536 received words theo oracle mới; kiểm tra riêng 256 bản tin
  sạch 8 bit, kể cả các bản tin có hai bit cuối khác `00`.
- Kiểm tra ACS/PSU ties, input đổi sau accept, enable lúc busy, done pulse,
  ranh giới nhận frame kế tiếp, reset/abort/restart và căn chỉnh metric/history.
- Vplan bằng Excel, checker tự động với directed tests; SVA không bắt buộc.
- Code coverage DUT: statement, branch, condition, expression đạt 100%; FSM
  coverage áp dụng nếu thiết kế có FSM. Exhaustive words không thay code coverage.
- Mục tiêu PPA: ít nhất 200 MHz; standard-cell area core không quá 7.000 µm²
  theo phạm vi core đã chọn trong nhánh; PDF đặt giới hạn công suất 1,5 mW.
  Phải báo rõ scope, clock, corner và activity khi đo công suất, cùng kết quả
  top tích hợp để đối chiếu với PDF. Không dùng power mặc định để khẳng định
  đã đạt công suất theo workload.

Build/run/snapshot mới đặt trong `experiment/`, testbench trong `tb/`, báo cáo
kiểm chứng trong `verification/`. Không sửa các ledger hoặc kết quả lịch sử.

## 5. Nội dung bị thay thế

Các yêu cầu cũ “6 payload + tail 00”, “fixed final S0”, “PSU removed”,
“chỉ lấy history_s0” và kiểm tra bắt buộc hai bit output cuối bằng `00` đã bị
thay thế bởi mục 1. Giao diện IU/OU bốn mode và nhận chồng II9 là giao diện/lịch
của RTL cũ, không phải yêu cầu của top mới.

Các tài liệu có ngày 2026-11-14 trở về trước và các JSON receipt vẫn giữ nguyên
để truy vết lịch sử. Khi triển khai mới, ưu tiên đặc tả này và quyết định mới
trực tiếp của người dùng.
