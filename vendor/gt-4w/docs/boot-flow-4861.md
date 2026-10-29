# Ascent GT Pro (4861) boot flow

Stock entry: `/usrdata/fpv/fpv_run_cx4861.sh` (also in `reverse/unpacked/usrdata-stock/fpv/`).

1. Wait for die temp under 105 C via `temp_measure.sh`.
2. Pin mux / devmem for SPI0, UART1, LSADC; export GPIO for board ID and 8030 power/reset.
3. `config_serial.sh` or `config_ether.sh` depending on `/factory/run_rndis_flag`.
4. Load MPP: `ko_cv610_20s/load3516cv610/fpv_load3516cv610_20s_debug -i`.
5. Read CV610 chip ID and GPIO7_0/7_1 straps for `board_ver` (16 vs 17).
6. Power-cycle Artosyn 8030 (GPIO62/59), read RF ID GPIOs, `ar_fpvhs_boardtype --hwver`.
7. **fpvOS hook** (if `air/start.sh` exists and `air/disable` absent): run kestrel-air path and exit.
8. Stock path: `boot_ar8030.sh 0`, probe `ar_ldyhs_sky --bb_hw_id`, map RF board, reload radio, then
   `ar_ldyhs_sky --board_type … --board_ver … --rf_board …` and `ar_fpvhs_mp_service`.

Camera (PS5280) lives inside `ar_ldyhs_sky` and ISP tuning under `fpv/tunning/cam_ps5280_*.bin`.
See `source/ps5280/` for the fpvOS glue driver that reuses the stock CMOS vtable at `0x267be4`.
