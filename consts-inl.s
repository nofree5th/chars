
.equiv FPS, 24

.equiv CONTENT_WIDTH, 12
.equiv CONTENT_HEIGHT, 15

#  elem = part of items
#   struct elem {
#     short row, col; // base item position
#     short count; // item count
#     struct item_offset {
#        short row_offset, col_offset; // relative to base item
#     } item_offset_list[count];
#   }
.equiv ELEM_START_ROW, BORDER_START_ROW + 4
.equiv ELEM_START_COL, BORDER_START_COL + CONTENT_WIDTH / 2
.equiv ELEM_MAX_SIZE, 2 + 2 + 2 + 4 * 10 # (row + col + count + max 10 elem_pos)
# struct offset
.equiv ELEM_OFFSET_ROW, 0
.equiv ELEM_OFFSET_COL, ELEM_OFFSET_ROW + 2
.equiv ELEM_OFFSET_COUNT, ELEM_OFFSET_COL + 2
.equiv ELEM_OFFSET_ITEM, ELEM_OFFSET_COUNT + 2

.equiv CLEAR_CHAR, ' '
.equiv REF_CHAR, '.'

.equiv CHAR_UP, 'w'
.equiv CHAR_DOWN, 's'
.equiv CHAR_LEFT, 'a'
.equiv CHAR_RIGHT, 'd'

# border
.equiv AREA_WIDTH, CONTENT_WIDTH + 2
.equiv AREA_HEIGHT, CONTENT_HEIGHT + 2
.equiv BORDER_ROW_CHAR, '.'
.equiv BORDER_COL_CHAR, ':'
.equiv BORDER_CORNER_CHAR, '.'
.equiv BORDER_START_ROW, 4
.equiv BORDER_START_COL, 25

# score
 .equiv SCORE_ROW, BORDER_START_ROW + AREA_WIDTH / 2
 .equiv SCORE_COL, BORDER_START_COL - 5
 .equiv README_ROW, 1
 .equiv README_COL, 1
