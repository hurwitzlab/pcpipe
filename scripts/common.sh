function lc() {
    wc -l $1 | cut -d ' ' -f 1
}
