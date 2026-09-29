#!/usr/bin/env bash
# Nhay toi cua so cua ung dung da gui thong bao (goi khi bam vao thong bao).
#   focus_app.sh <desktop-entry> <app-name>
# Chon cua so khop class gan day nhat (focusHistoryID nho nhat) va focus no,
# Hyprland tu chuyen sang workspace chua cua so do.
de=$(tr '[:upper:]' '[:lower:]' <<<"${1%.desktop}")
app=$(tr '[:upper:]' '[:lower:]' <<<"$2")
[[ -z $de && -z $app ]] && exit 0

# Doi app xu ly action "default" (vd Chrome chuyen dung tab) roi moi focus
sleep 0.15

addr=$(hyprctl clients -j 2>/dev/null | jq -r --arg de "$de" --arg app "$app" '
  def norm: ascii_downcase | gsub("[ _]"; "-");
  def last: split(".") | .[-1];
  [ .[] | select(.mapped and (.hidden | not))
        | . as $w
        | ([$w.class, $w.initialClass] | map(select(. != null and . != "") | norm)) as $cls
        | select(any($cls[];
            . as $c
            | ($de != "" and ($c == ($de|norm) or ($c|last) == ($de|norm|last)))
              or ($app != "" and ($c == ($app|norm) or ($c|last) == ($app|norm)
                                   or ($c | startswith($app|norm))))))
  ] | sort_by(.focusHistoryID) | .[0].address // empty')

[[ -n $addr ]] && hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >/dev/null
exit 0
