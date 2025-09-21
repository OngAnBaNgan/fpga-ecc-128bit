# HDL Implementation of 128-bit Elliptic Curve Cryptography (ECC) on FPGA

## 1. Tổng quan

Đây là dự án triển khai phần cứng (HDL) của thuật toán mã hóa đường cong Elliptic (ECC) **phiên bản 128-bit**. Dự án được viết bằng Verilog và được cấu hình để tổng hợp trên FPGA **Intel Cyclone IV E** bằng bộ công cụ Intel Quartus Prime.

Thiết kế này đã được tối ưu hóa để cân bằng giữa hiệu năng và tài nguyên sử dụng, khác với kiến trúc 3 lõi ban đầu được đề cập trong luận văn tham khảo. Dự án bao gồm một module giao tiếp SPI (`spi_ecc_128bit.v`), cho phép FPGA hoạt động như một co-processor (bộ đồng xử lý), nhận lệnh và dữ liệu từ một vi điều khiển chủ (ví dụ như ESP32).

## 2. Các tính năng chính

* **Thuật toán:** Triển khai mã hóa đường cong Elliptic **128-bit**.
* **Ngôn ngữ:** Verilog HDL.
* **Nền tảng mục tiêu:** FPGA **Intel Cyclone IV E (EP4CE6E22C8)**.
* **Bộ công cụ:** **Intel Quartus Prime** (phiên bản 18.1.0 Lite Edition).
* **Giao tiếp:** Tích hợp sẵn wrapper với giao tiếp **SPI** và các chân **GPIO** để bắt tay (handshaking), dễ dàng kết nối với vi điều khiển.
* **Tối ưu hóa:** Cấu hình trong Quartus được thiết lập để **cân bằng (BALANCED)** tài nguyên và tốc độ, đồng thời bật các tùy chọn tối ưu hóa vật lý (physical synthesis).

## 3. Cấu trúc và thiết lập

* `/rtl`: Chứa toàn bộ mã nguồn Verilog HDL của dự án. Các file đang được sử dụng cho phiên bản này bao gồm:
    * `spi_ecc_128bit.v` (Module Top-level)
    * `ecc_top_128bit.v`
    * `main_128bit.v`
    * `core1_128bit.v`
    * `ALU_128bit.v`
* `/quartus`: Chứa các tệp dự án của Intel Quartus (`ecc.qpf`, `ecc.qsf`).
    * File `ecc.qsf` đã được cấu hình sẵn để tổng hợp đúng các module 128-bit và gán chân cho chip EP4CE6E22C8.

## 4. Hướng dẫn sử dụng

1.  Mở tệp dự án `ecc.qpf` trong phần mềm Intel Quartus Prime.
2.  Chạy quá trình **Compile Design** để tổng hợp mã nguồn.
3.  Sử dụng **Programmer** để nạp file `.sof` (tạo ra trong thư mục `output_files`) xuống bo mạch FPGA có chip Cyclone IV E.
4.  Kết nối FPGA với vi điều khiển qua giao tiếp SPI và GPIO theo sơ đồ chân đã được định nghĩa trong file `ecc.qsf`.

## 5. Tham khảo học thuật

Kiến trúc ban đầu của dự án này dựa trên các khái niệm được mô tả trong luận văn:
* **Tên luận văn:** *Hardware Implementation of an Elliptic Curve Cryptosystem Using Three Finite Field Multipliers*.
* **Tác giả:** Yu, Zhen.
* **Link:** [http://ecommons.usask.ca/bitstream/handle/10388/etd-05032010-135617/Yu_thesis.pdf](http://ecommons.usask.ca/bitstream/handle/10388/etd-05032010-135617/Yu_thesis.pdf)

**Lưu ý:** Phiên bản hiện tại là một biến thể **128-bit** đã được sửa đổi và không hoàn toàn giống với kiến trúc 163-bit gốc trong luận văn.
