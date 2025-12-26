// We want to provide:
//   1. A backlink to the casting page.
//   2. Hide or show line judgements depending on relevancy.
//
// The HTML of each page is a modified version of
// http://www2.unipr.it/~deyoung/I_Ching_Wilhelm_Translation.html
// where I have added hyperlinks and semantics and stuff.

const hexagramsByIndex =
    // 0-indexed, so the 0th hexagram is Hexagram 1.
    // Note that the binary is read so that left to right is bottom to top.
    [ 63, 0, 34, 17, 58, 23, 16, 2, 59, 55, 56, 7, 47, 61, 8, 4, 38, 25, 48, 3, 37, 41, 1, 32, 39, 57, 33, 30, 18, 45, 14, 28, 15, 60, 5, 40, 43, 53, 10, 20, 49, 35, 62, 31, 6, 24, 22, 26, 46, 29, 36, 9, 11, 52, 44, 13, 27, 54, 19, 50, 51, 12, 42, 21];
// We can derive the other direction of the mapping.
const hexagramsByLines = hexagramsByIndex.reduce((arr, n, i) => (arr[n] = i+1, arr), []);

function numbersToHexagram(numbers) {
    // Returns a pair of integers representing a hexagram and its alternative.
    if (numbers.length != 6 || numbers.some((n) => n < 6 || n > 9)) {
        throw new Error("invalid numbers");
    }

    let binaryLines = 0;
    let changedLines = 0;
    for (let i=0; i<6; i++) {
        if (numbers[5-i] % 2 == 1) { // 7 and 9 are yang, i.e. 1
            binaryLines |= (1 << i);
            // 6 and 8 are yin, i.e. 0, so we don't have to do anything.
        }
        if (numbers[5-i] % 3 == 0) { // 6 and 9 are old, i.e. 1 in this bitmask
            changedLines |= (1 << i);
        }
    }
    return { hexagram: hexagramsByLines[binaryLines],
             alternative: changedLines == 0 ? null : hexagramsByLines[binaryLines ^ changedLines] };
}

const numbers = [];

function dieGracefully() {
    // In case of invalid or unspecified URL parameters, show all line
    // judgments and remove the parameters.
    const url = new URL(window.location.href);
    url.searchParams.delete('c');
    url.searchParams.delete('alt');
    window.history.pushState(null, '', url.toString());

    const lineJudgements = document.querySelectorAll('.lj');
    for (let lj of lineJudgements) {
        lj.classList.add('show');
    }

}

function setup() {
    const paramsString = window.location.search;
    const searchParams = new URLSearchParams(paramsString);
    const c = searchParams.get("c");
    const isAlt = searchParams.get("alt");

    if (!c) {
        // In this case and the one below it's possible that alt=true but we
        // can't do anything with that if we don't know the numbers, so we
        // revert to default behavior.
        console.log("No numbers provided in URL params. Defaulting to show all line judgments and removing parameters.");
        dieGracefully();
        return;
    }

    const numbersValid = c && c.length == 6 && Array.from(c).every((ch) => ch == '6' || ch == '7' || ch == '8' || ch == '9');

    if (!numbersValid) {
        console.warn("Numbers invalid. Defaulting to show all line judgments and removing parameters.");
        dieGracefully();
        return;
    }

    for (let i = 0; i < 6; i++) numbers.push(parseInt(c.charAt(i)));

    const {hexagram, alternative} = numbersToHexagram(numbers);

    if (isAlt && !alternative) {
        console.warn("URL params claim this is an alternative but no old lines in casting. Defaulting to show all line judgments and removing parameters.");
        dieGracefully();
        return;
    }

    if (!isAlt) {
        for (let i = 0; i < 6; i++) {
            const lineJudgements = document.querySelectorAll(`.lj.lj${i+1}-${numbers[i]}`);
            for (let lj of lineJudgements) {
                lj.classList.add('show');
            }
        }
        
        if (numbers.every((x) => x == 6) || numbers.every((x) => x == 9)) {
            const lineJudgements = document.querySelectorAll(`.lj.moving`);
            for (let lj of lineJudgements) {
                lj.classList.add('show');
            }
        }

        if (alternative) {
            // Show the alt if it exists.
            const p = document.getElementById('alternative');
            p.classList.add('show');
            const ch = `&#${19904 + alternative - 1};`;
            p.innerHTML = `Changing to <a href="${alternative}.html?c=${c}&alt=true">${ch} Hexagram ${alternative}</a>.`;
        }
    } else {
        // This is an alt; show no judgments and link to the original.
        const p = document.getElementById('alternative');
        p.classList.add('show');
        const ch = `&#${19904 + hexagram - 1};`;
        p.innerHTML = `Changing from <a href="${hexagram}.html?c=${c}">${ch} Hexagram ${hexagram}</a>.`;
    }

    const back = document.getElementById('back');
    const url = new URL(back.href);
    url.searchParams.set('c', c);
    back.href = url;
}

if (document.readyState === 'loading') {
    document.addEventListener("DOMContentLoaded", () => {
        setup();
    });
} else {
    setup();
}

