#!/bin/bash
# In ra thiết bị USB cắm ngoài (bỏ qua thiết bị gắn sẵn trong máy): "loại<TAB>tên"
for d in /sys/bus/usb/devices/[0-9]*-*; do
  [[ $d == *:* ]] && continue
  [ "$(cat "$d/removable" 2>/dev/null)" = removable ] || continue
  name=$(cat "$d/product" 2>/dev/null); [ -z "$name" ] && name="$(cat "$d/manufacturer" 2>/dev/null) USB"
  cls=" $(cat "$d"/*:*/bInterfaceClass 2>/dev/null | tr '\n' ' ')"
  case "$cls" in
    *" 06 "*|*" 0e "*) kind=camera ;;
    *" 08 "*)          kind=storage ;;
    *" 03 "*)          kind=input ;;
    *" 01 "*)          kind=audio ;;
    *)                 kind=other ;;
  esac
  [[ "$name" =~ ZV-|ILCE|DSC|EOS|Camera ]] && kind=camera
  printf '%s\t%s\n' "$kind" "$name"
done
