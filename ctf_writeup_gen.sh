#!/bin/bash

# ============================================================
#   CTF Writeup Generator - Dynamic & Reusable
#   Author: super
#   Usage: bash ctf_writeup_gen.sh
# ============================================================

BOLD="\e[1m"
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

PROMPT_RESULT=""
MULTILINE_RESULT=""

ask() {
    local question="$1"
    local default="$2"
    if [[ -n "$default" ]]; then
        echo -ne "${CYAN}${question}${RESET} ${YELLOW}[${default}]${RESET}: "
    else
        echo -ne "${CYAN}${question}${RESET} "
    fi
    read -r PROMPT_RESULT
    if [[ -z "$PROMPT_RESULT" && -n "$default" ]]; then
        PROMPT_RESULT="$default"
    fi
}

ask_multiline() {
    local question="$1"
    MULTILINE_RESULT=""
    echo -e "${CYAN}${question}${RESET} ${YELLOW}(press Enter twice to finish)${RESET}"
    echo -ne "> "
    while IFS= read -r line; do
        [[ -z "$line" ]] && break
        MULTILINE_RESULT+="${line}\n"
        echo -ne "> "
    done
}

confirm() {
    echo -ne "${YELLOW}${1} (y/n): ${RESET}"
    read -r yn
    [[ "$yn" =~ ^[Yy]$ ]]
}

divider() {
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}  $1${RESET}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

# ── Banner ──────────────────────────────────────
echo -e "${CYAN}${BOLD}"
echo "   ██████╗████████╗███████╗    ██╗    ██╗██████╗ ██╗████████╗███████╗██╗   ██╗██████╗"
echo "  ██╔════╝╚══██╔══╝██╔════╝    ██║    ██║██╔══██╗██║╚══██╔══╝██╔════╝██║   ██║██╔══██╗"
echo "  ██║        ██║   █████╗      ██║ █╗ ██║██████╔╝██║   ██║   █████╗  ██║   ██║██████╔╝"
echo "  ██║        ██║   ██╔══╝      ██║███╗██║██╔══██╗██║   ██║   ██╔══╝  ██║   ██║██╔═══╝"
echo "  ╚██████╗   ██║   ██║         ╚███╔███╔╝██║  ██║██║   ██║   ███████╗╚██████╔╝██║"
echo "   ╚═════╝   ╚═╝   ╚═╝          ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝  ╚══════╝ ╚═════╝ ╚═╝"
echo -e "${RESET}"
echo -e "${YELLOW}          Dynamic CTF Writeup Generator${RESET}"
echo -e "${YELLOW}          ================================${RESET}\n"

# ── Output Path ─────────────────────────────────
divider "📂 Output Path"

ask "Writeups base directory" "/mnt/shared/CTF-Writeups"
WRITEUPS_ROOT="$PROMPT_RESULT"

# ── CTF Event Details ───────────────────────────
divider "📋 CTF Event Details"

ask "CTF Name (e.g. PerfectRoot, niteCTF, CyberGame):"
CTF_NAME="$PROMPT_RESULT"

ask "Year" "$(date +%Y)"
CTF_YEAR="$PROMPT_RESULT"

ask "Date (e.g. December 7, 2025 or March–May 2026)" "$(date '+%B %d, %Y')"
CTF_DATE="$PROMPT_RESULT"

ask "Your GitHub handle" "5up3rUs3r"
AUTHOR="$PROMPT_RESULT"

ask "GitHub profile URL" "https://github.com/5up3rUs3r"
GITHUB="$PROMPT_RESULT"

ask "Final placement (e.g. 33rd — leave blank if none)"
PLACEMENT="$PROMPT_RESULT"

ask "Total CTFtime rating points earned (e.g. 0.946 — leave blank if none)"
RATING_PTS="$PROMPT_RESULT"

# ── Event Info Block ─────────────────────────────
divider "🌐 Event Info Block"
echo -e "${YELLOW}  (Fill these in for the ## Event Info section — leave blank to skip the whole block)${RESET}\n"

ask "  Organizer name (e.g. Cryptonite MIT, SK-CERT — leave blank if none)"
ORGANIZER="$PROMPT_RESULT"

ask "  One-sentence event description (organizer will be bolded inline if provided):"
EVENT_DESC="$PROMPT_RESULT"

ask "  CTFtime URL (leave blank if none)"
CTFTIME_URL="$PROMPT_RESULT"

ask "  Official platform/repo URL (leave blank if none)"
PLATFORM_URL="$PROMPT_RESULT"

ask "  Platform URL label (e.g. Official URL, Official Repo, Platform)" "Official URL"
PLATFORM_LABEL="$PROMPT_RESULT"

ask "  CTFtime rating weight (e.g. 96.88 — leave blank if none)"
RATING_WEIGHT="$PROMPT_RESULT"

# ── Table Options ────────────────────────────────
divider "📊 Challenge Table Options"

INCLUDE_FLAG_COL="false"
confirm "Include flag column in the challenges table?" && INCLUDE_FLAG_COL="true"

EXTRA_COL=""
ask "Extra table column name (e.g. Difficulty, Vulnerability, Status — leave blank for none)"
EXTRA_COL="$PROMPT_RESULT"

# ── Challenge Setup ─────────────────────────────
divider "🚩 Challenge Setup"

ask "How many challenges did you solve?"
TOTAL_CHALLENGES="$PROMPT_RESULT"
TOTAL_POINTS=0

declare -a C_NAME C_CAT C_PTS C_DIFF C_DESC C_SERVER C_TLDR C_FLAG C_TOOLS C_TAKEAWAYS C_STEPS C_INIT C_EXTRA

for ((i=1; i<=TOTAL_CHALLENGES; i++)); do
    divider "🔥 Challenge $i of $TOTAL_CHALLENGES"

    ask "  Challenge name:"
    C_NAME[$i]="$PROMPT_RESULT"

    ask "  Category (WEB/MISC/PWN/REV/CRYPTO/FORENSICS/WEB3/OSINT):"
    C_CAT[$i]="$PROMPT_RESULT"

    ask "  Points:"
    C_PTS[$i]="$PROMPT_RESULT"
    TOTAL_POINTS=$((TOTAL_POINTS + C_PTS[$i]))

    ask "  Difficulty" "Medium"
    C_DIFF[$i]="$PROMPT_RESULT"

    ask_multiline "  Challenge description:"
    C_DESC[$i]="$MULTILINE_RESULT"

    ask "  File / Server / URL (leave blank if none)"
    C_SERVER[$i]="$PROMPT_RESULT"

    ask "  TL;DR — one-line summary of your solution:"
    C_TLDR[$i]="$PROMPT_RESULT"

    ask "  Flag (e.g. CTF{...}):"
    C_FLAG[$i]="$PROMPT_RESULT"

    if [[ -n "$EXTRA_COL" ]]; then
        ask "  ${EXTRA_COL} value (for table):"
        C_EXTRA[$i]="$PROMPT_RESULT"
    fi

    ask_multiline "  Initial Analysis — key observations before the main steps (leave blank to skip):"
    C_INIT[$i]="$MULTILINE_RESULT"

    ask "  Number of solution steps:"
    NUM_STEPS="$PROMPT_RESULT"
    all_steps=""

    for ((s=1; s<=NUM_STEPS; s++)); do
        echo -e "\n${YELLOW}  -- Step $s of $NUM_STEPS --${RESET}"

        ask "    Step title (e.g. Identify the Vulnerability):"
        S_TITLE="$PROMPT_RESULT"

        ask_multiline "    Step description:"
        S_DESC="$MULTILINE_RESULT"

        S_CODE=""
        S_LANG="bash"
        if confirm "    Add a code block?"; then
            ask "    Language" "bash"
            S_LANG="$PROMPT_RESULT"
            ask_multiline "    Paste your code:"
            S_CODE="$MULTILINE_RESULT"
        fi

        all_steps+="^^TITLE::${S_TITLE}^^DESC::${S_DESC}^^CODE::${S_CODE}^^LANG::${S_LANG}^^END"
    done
    C_STEPS[$i]="$all_steps"

    ask "  Tools used (comma-separated, e.g. nmap, burpsuite, python):"
    C_TOOLS[$i]="$PROMPT_RESULT"

    ask_multiline "  Key Takeaways (one per line):"
    C_TAKEAWAYS[$i]="$MULTILINE_RESULT"

    echo -e "\n${GREEN}  ✅ Challenge '${C_NAME[$i]}' saved!${RESET}"
done

# ── About Text ───────────────────────────────────
divider "📝 About Section"

ask_multiline "About text for the event README (1–2 sentences on the event and your result):"
EVENT_ABOUT="$MULTILINE_RESULT"
if [[ -z "$EVENT_ABOUT" || "$EVENT_ABOUT" == $'\n' ]]; then
    EVENT_ABOUT="These writeups document my solutions for ${CTF_NAME} CTF ${CTF_YEAR}.\n"
fi

# ── Build folder structure ──────────────────────
divider "📁 Generating Writeup Files"

SAFE_CTF=$(echo "$CTF_NAME" | tr ' ' '-')
BASE="${WRITEUPS_ROOT}/${SAFE_CTF}-${CTF_YEAR}"

for ((i=1; i<=TOTAL_CHALLENGES; i++)); do
    SAFE=$(echo "${C_NAME[$i]}" | tr ' ' '-')
    mkdir -p "${BASE}/${SAFE}"
done
echo -e "${GREEN}✅ Folders created at: ${BASE}${RESET}"

# ── Build dynamic table header ───────────────────
TABLE_HEADER="| Challenge | Category | Points |"
TABLE_SEP="|-----------|----------|--------|"
if [[ -n "$EXTRA_COL" ]]; then
    TABLE_HEADER+=" ${EXTRA_COL} |"
    TABLE_SEP+="------------|"
fi
if [[ "$INCLUDE_FLAG_COL" == "true" ]]; then
    TABLE_HEADER+=" Flag |"
    TABLE_SEP+="------|"
fi

# ── Main README ─────────────────────────────────
{
echo "# ${CTF_NAME} CTF ${CTF_YEAR} - Writeups"
echo ""
echo "**Author:** [${AUTHOR}](${GITHUB})  "
echo "**Date:** ${CTF_DATE}  "
[[ -n "$PLACEMENT" ]] && echo "**Final Placement:** ${PLACEMENT}  "
echo "**Total Points:** ${TOTAL_POINTS}  "
[[ -n "$RATING_PTS" ]] && echo "**CTFtime Rating Points:** ${RATING_PTS}  "
echo ""

# Event Info block (only if at least one field is provided)
if [[ -n "$EVENT_DESC" || -n "$CTFTIME_URL" || -n "$PLATFORM_URL" || -n "$ORGANIZER" ]]; then
    echo "## Event Info"
    echo ""
    if [[ -n "$EVENT_DESC" ]]; then
        if [[ -n "$ORGANIZER" ]]; then
            echo "> ${EVENT_DESC} Organized by **${ORGANIZER}**.  "
        else
            echo "> ${EVENT_DESC}  "
        fi
    fi
    [[ -n "$CTFTIME_URL" ]] && echo "> **CTFtime:** ${CTFTIME_URL}  "
    [[ -n "$PLATFORM_URL" ]] && echo "> **${PLATFORM_LABEL}:** ${PLATFORM_URL}  "
    [[ -n "$RATING_WEIGHT" ]] && echo "> **Rating Weight:** ${RATING_WEIGHT}"
    echo ""
fi

echo "## Challenges Solved"
echo ""
echo "$TABLE_HEADER"
echo "$TABLE_SEP"

for ((i=1; i<=TOTAL_CHALLENGES; i++)); do
    SAFE=$(echo "${C_NAME[$i]}" | tr ' ' '-')
    ROW="| [${C_NAME[$i]}](./${SAFE}/README.md) | ${C_CAT[$i]} | ${C_PTS[$i]} |"
    [[ -n "$EXTRA_COL" ]] && ROW+=" ${C_EXTRA[$i]} |"
    [[ "$INCLUDE_FLAG_COL" == "true" ]] && ROW+=" \`${C_FLAG[$i]}\` |"
    echo "$ROW"
done

echo ""
echo "## Quick Links"
echo ""
echo "- [My GitHub](${GITHUB})"
echo "- [CTF Writeups Repo](${GITHUB}/CTF-Writeups)"
echo ""
echo "## About"
echo ""
echo -e "${EVENT_ABOUT}"
} > "${BASE}/README.md"

echo -e "${GREEN}✅ Main README.md created${RESET}"

# ── Individual writeups ─────────────────────────
for ((i=1; i<=TOTAL_CHALLENGES; i++)); do
    SAFE=$(echo "${C_NAME[$i]}" | tr ' ' '-')
    OUT="${BASE}/${SAFE}/README.md"

    {
    echo "# ${C_NAME[$i]} (${C_PTS[$i]} pts - ${C_CAT[$i]})"
    echo ""
    echo "## Challenge Description"
    echo ""
    echo "> $(echo -e "${C_DESC[$i]}")"
    echo ""
    [[ -n "${C_SERVER[$i]}" ]] && echo "**File/Server/URL:** \`${C_SERVER[$i]}\`  " && echo ""
    echo "## TL;DR"
    echo ""
    echo "${C_TLDR[$i]}"
    echo ""

    # Initial Analysis section
    if [[ -n "${C_INIT[$i]}" && "${C_INIT[$i]}" != $'\n' ]]; then
        echo "## Initial Analysis"
        echo ""
        echo -e "${C_INIT[$i]}"
        echo ""
    fi

    echo "## Solution"
    echo ""

    step_num=1
    IFS='^^' read -ra CHUNKS <<< "${C_STEPS[$i]}"
    declare -A SDATA
    for chunk in "${CHUNKS[@]}"; do
        [[ "$chunk" == TITLE::* ]] && SDATA[title]="${chunk#TITLE::}"
        [[ "$chunk" == DESC::*  ]] && SDATA[desc]="${chunk#DESC::}"
        [[ "$chunk" == LANG::*  ]] && SDATA[lang]="${chunk#LANG::}"
        [[ "$chunk" == CODE::*  ]] && SDATA[code]="${chunk#CODE::}"
        if [[ "$chunk" == "END" ]]; then
            echo "### Step ${step_num}: ${SDATA[title]}"
            echo ""
            echo -e "${SDATA[desc]}"
            if [[ -n "${SDATA[code]}" && "${SDATA[code]}" != $'\n' ]]; then
                echo "\`\`\`${SDATA[lang]}"
                echo -e "${SDATA[code]}"
                echo "\`\`\`"
            fi
            echo ""
            step_num=$((step_num+1))
            unset SDATA
            declare -A SDATA
        fi
    done

    echo "## Flag"
    echo ""
    echo '```'
    echo "${C_FLAG[$i]}"
    echo '```'
    echo ""
    echo "## Key Takeaways"
    echo ""
    while IFS= read -r line; do
        [[ -n "$line" ]] && echo "- ${line}"
    done <<< "$(echo -e "${C_TAKEAWAYS[$i]}")"
    echo ""
    echo "## Tools Used"
    echo ""
    IFS=',' read -ra TOOLS <<< "${C_TOOLS[$i]}"
    for t in "${TOOLS[@]}"; do
        echo "- \`$(echo "$t" | xargs)\`"
    done
    } > "$OUT"

    echo -e "${GREEN}✅ ${C_NAME[$i]} -> ${OUT}${RESET}"
done

# ── Done ────────────────────────────────────────
divider "🎉 All Done!"
echo -e "${BOLD}${GREEN}Writeups saved to:${RESET} ${BASE}"
echo ""
echo -e "${YELLOW}Quick actions:${RESET}"
echo -e "  📂 Open folder  : ${CYAN}explorer.exe \$(wslpath -w \"${BASE}\")${RESET}"
echo -e "  📖 View README  : ${CYAN}cat \"${BASE}/README.md\"${RESET}"
echo -e "  🌐 Push to Git  : ${CYAN}cd \"${WRITEUPS_ROOT}\" && git add \"${SAFE_CTF}-${CTF_YEAR}/\" && git commit -m 'Add ${CTF_NAME} ${CTF_YEAR} writeups' && git push${RESET}"
echo ""
echo -e "${GREEN}${BOLD}Happy hacking! 🚀${RESET}"
