# Argus Excel Format Specification

## Overview
This document provides a comprehensive specification of the Argus Excel file formats used for importing call center metrics data. The analysis is based on actual Excel files from projects Б (Бизнес), ВТМ, И, and Ф (ФС).

## File Structure

### General Structure
- **File Format**: Excel (.xlsx)
- **Encoding**: UTF-8
- **Header Rows**: 3 rows
  - Row 1: Report title with date range (e.g., "Входящие проекты [ c 24.01.2025 по 24.05.2025(+5) ]")
  - Row 2: Empty row
  - Row 3: Column headers
- **Data Start**: Row 4 (0-indexed row 3)

### File Naming Convention
```
ОтчетВходящиеПроекты-[PROJECT]-[INTERVAL].xlsx
```
Where:
- `[PROJECT]`: Project code (Бизнес/Б 24, ВТМ, И, ФС 24/Ф 24)
- `[INTERVAL]`: Time interval (15м, 30м, 1ч)

## Column Specifications

### Standard Format (26 columns)
Used in most files, especially in the "15" folder:

| Column # | Column Name | Data Type | Format | Description |
|----------|-------------|-----------|---------|-------------|
| 1 | Период | String | DD.MM.YYYY HH:MM | Date and time of the interval |
| 2 | CDO | Integer | Whole number | Calls Delivered to Operator |
| 3 | HC | Integer | Whole number | Handled Calls |
| 4 | SHC | Float | 0.0-100.0, 1 decimal | Service Level (%) |
| 5 | SHC (-AC5) | Float | 0.0-100.0, 1 decimal | Service Level excluding calls < 5 sec |
| 6 | HC (SL) | Integer | Whole number | Handled Calls within Service Level |
| 7 | SL | Float | 0.0-100.0, 1 decimal | Service Level percentage |
| 8 | SL on HC | Float | 0.0-100.0, 1 decimal | Service Level based on Handled Calls |
| 9 | AC | Integer | Whole number | Abandoned Calls |
| 10 | AC(5) | Integer | Whole number | Abandoned Calls within 5 seconds |
| 11 | LCR | Float | 0.0-100.0, 1 decimal | Lost Call Rate (%) |
| 12 | FC | Integer | Whole number | Failed Calls |
| 13 | TT | Integer | Whole number | Total Talk Time (seconds) |
| 14 | OTT | Integer | Whole number | Outbound Talk Time (seconds) |
| 15 | HT | Integer | Whole number | Hold Time (seconds) |
| 16 | THT | Integer | Whole number | Total Handle Time (seconds) |
| 17 | AHT | Integer | Whole number | Average Handle Time (seconds) |
| 18 | ACW | Integer | Whole number | After Call Work time (seconds) |
| 19 | THT (+ACW) | Integer | Whole number | Total Handle Time including ACW |
| 20 | AHT (+ACW) | Integer | Whole number | Average Handle Time including ACW |
| 21 | TWT (HC) | Integer | Whole number | Total Wait Time for Handled Calls |
| 22 | AWT (HC) | Float | Whole number or 1 decimal | Average Wait Time for Handled Calls |
| 23 | MWT (HC) | Integer | Whole number | Maximum Wait Time for Handled Calls |
| 24 | TWT (AC) | Integer | Whole number | Total Wait Time for Abandoned Calls |
| 25 | AWT (AC) | Float | Whole number or 1 decimal | Average Wait Time for Abandoned Calls |
| 26 | MWT (AC) | Integer | Whole number | Maximum Wait Time for Abandoned Calls |

### Extended Format (27 columns)
Used in some files in the "2430_xlsx2" folder (specifically for projects Б 24 and Ф 24):

| Column # | Column Name | Data Type | Format | Description |
|----------|-------------|-----------|---------|-------------|
| 1 | Период | String | DD.MM.YYYY HH:MM | Date and time of the interval |
| 2 | Проект | String | Text | Project name (e.g., "ВТМ_Бизнес 24") |
| 3-27 | [Same as columns 2-26 in Standard Format] | - | - | - |

## Data Type Details

### Date/Time Format (Период)
- **Format**: `DD.MM.YYYY HH:MM`
- **Examples**: 
  - `24.01.2025 00:15`
  - `24.01.2025 13:30`
  - `24.01.2025 01:00`
- **Time Intervals**:
  - 15-minute: Times end in :00, :15, :30, :45
  - 30-minute: Times end in :00, :30
  - 1-hour: Times end in :00

### Numeric Formats
1. **Integer columns**: Whole numbers, no decimals
   - Can contain very large values (e.g., TT can reach 145,487,172)
   - Missing values represented as 0 or NaN

2. **Float columns**: 
   - Percentage fields (SHC, SL, LCR): 0.0 to 100.0 with 1 decimal place
   - Average time fields (AWT): Can be whole numbers or have 1 decimal place
   - Missing values represented as NaN

3. **Special cases**:
   - CDO column in some files contains string values (e.g., "1" instead of 1)
   - Missing AWT (AC) values are represented as NaN when no abandoned calls exist

## Project-Specific Variations

### Project Б (Бизнес)
- In "15" folder: Uses project code "Бизнес"
- In "2430_xlsx2" folder: Uses project code "Б 24"
- May include "Проект" column with value "ВТМ_Бизнес 24"

### Project ВТМ
- Consistent naming across folders
- Standard 26-column format

### Project И
- Consistent naming across folders
- Standard 26-column format
- Often has float values in SL-related columns

### Project Ф (ФС)
- In "15" folder: Uses project code "ФС 24"
- In "2430_xlsx2" folder: Uses project code "Ф 24"
- May include "Проект" column

## Value Ranges

Based on analyzed data:

| Metric | Typical Min | Typical Max | Notes |
|--------|-------------|-------------|--------|
| CDO | 0 | 1,006,430 | Call volume varies significantly |
| HC | 0 | 683,047 | Usually less than CDO |
| SHC, SL, LCR | 0.0 | 100.0 | Percentages with 1 decimal |
| TT, THT | 0 | 153,682,985 | Time in seconds, can be very large |
| AHT | 0 | 2,641 | Average times typically under 1 hour |
| ACW | 0 | 10,730,997 | Can be unusually large in some cases |

## Import Considerations

1. **Header Detection**: Skip first 3 rows to reach data
2. **Column Mapping**: Check for presence of "Проект" column (27 vs 26 columns)
3. **Data Type Conversion**:
   - Convert CDO to integer (may be string in source)
   - Handle NaN values appropriately (especially in AWT columns)
   - Preserve 1 decimal place for percentage fields
4. **Character Encoding**: Ensure proper handling of Cyrillic characters in column names
5. **Date Parsing**: Use `DD.MM.YYYY HH:MM` format for period column

## File Validation Rules

1. **Required columns**: All 26 (or 27 with Проект) columns must be present
2. **Date sequence**: Periods should follow consistent intervals (15m, 30m, or 1h)
3. **Percentage bounds**: SHC, SL, LCR values must be between 0 and 100
4. **Logical constraints**:
   - HC ≤ CDO (handled calls cannot exceed delivered calls)
   - HC (SL) ≤ HC (calls within SL cannot exceed total handled)
   - AHT = THT / HC (when HC > 0)
   - AWT values should be NaN when corresponding call count is 0

## Notes

1. Files in different folders may represent different time periods or data sources
2. The "Проект" column appears to be used for consolidated reports containing multiple projects
3. Some files have numbers in parentheses in their names (e.g., "(1)"), possibly indicating versions or duplicates
4. All time-based metrics are in seconds
5. Percentage fields use period (.) as decimal separator