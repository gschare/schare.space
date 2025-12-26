// I Ching casting
//
// Made with no AI.
// Not for any noble reason. I just thought it would be a fun afternoon project
// to do it by hand.
//
// 64 hexagrams, constructed by making all possible pairs of 8 trigrams.
//
// Each hexagram is a solid or broken line, i.e. six digit binary code. We will
// treat 0 as a broken line and 1 as a solid line, by convention.
//
// In practice you generate the hexagrams with coin tosses, but not directly.
// We will discuss that algorithm later.
//
// For ease we will encode this using binary, assigning each hexagram a number
// whose binary representation matches its broken or unbroken lines.  This way
// we can do binary operations to get alternatives.  Frankly the fixed bound
// and tiny size of these computations makes it absurd to bother with these
// optimizations but I find it amusing.

const hexagramsByIndex =
    // 0-indexed, so the 0th hexagram is Hexagram 1.
    // Note that the binary is read so that left to right is bottom to top.
    [ 63, 0, 34, 17, 58, 23, 16, 2, 59, 55, 56, 7, 47, 61, 8, 4, 38, 25, 48, 3, 37, 41, 1, 32, 39, 57, 33, 30, 18, 45, 14, 28, 15, 60, 5, 40, 43, 53, 10, 20, 49, 35, 62, 31, 6, 24, 22, 26, 46, 29, 36, 9, 11, 52, 44, 13, 27, 54, 19, 50, 51, 12, 42, 21];
// We can derive the other direction of the mapping.
const hexagramsByLines = hexagramsByIndex.reduce((arr, n, i) => (arr[n] = i+1, arr), []);

// The coin tosses generate numbers 6 to 9 according to an algorithm.
//
// The numbers correspond to yin or yang and old or young. The yin and yang
// correspond to broken or solid lines, and old and young don't correspond to a
// feature of the hexagrams themselves, but to your consultation; wherever a
// line is old, there is a special line judgment, and you also consult the
// alternative hexagram where each old line is its young opposite (old yang ->
// young yin, old yin -> young yang). As a result there are 4096 possibilities
// for results from a single consultation, not 64.
//
// At this point I will make a note on terminology.
// 2 _lines_: yin (broken) or yang (solid).
// 2 _stabilities_: old (changing) or young (unchanging).
// 4 _numbers_ from combining a line and a stability: called 6-9.
// 64 _hexagrams_ from stacking 6 lines.
// 8 _trigram_ if you stack 3 lines. Not important here.
// 4096 _consultations_ from six stacked numbers (4^6).
//
// The number is computed by adding up the result of three coin tosses where
// heads is 2 and tails is 3.
function threeCoinsToNumber(firstToss, secondToss, thirdToss) {
    return 6 + firstToss + secondToss + thirdToss;
}

// The method above has probabilities that are different from the traditional
// process with yarrow stalks. There is an alternative algorithm that uses one
// special coin, but this requires re-flipping, which is a less ideal user
// experience. Although we could do it silently in the background, I would
// prefer another method with the same probabilities as the yarrow. That is by
// running two rounds of tossing two identical coins, with no special coins.

function twoCoinsToNumber(firstToss, secondToss, thirdToss, fourthToss) {
    return 2 + !(firstToss && secondToss) + 4 + thirdToss + fourthToss;

}

// Here is the modified three coin method with background reflipping.
// First, some helpers.
function randInt(start, end) {
    return Math.floor(Math.random() * (end-start)) + start;
}
function randBool() {
    return Math.floor(Math.random() * 2) != 0;
}
function modifiedThreeCoinsToNumber(firstToss, secondToss, thirdSpecialToss) {
    if (!firstToss && !secondToss && !thirdSpecialToss) {
        return randBool() ? 8 : 6;
    }
    else if (!firstToss && !secondToss && thirdSpecialToss) {
        return randBool() ? 7 : 9;
    }
    else {
        return 6 + firstToss + secondToss + thirdSpecialToss;
    }
}

// We will obtain the values of the tosses from a form.

// We will work with the numbers and use a function to convert them to the
// hexagram and the alternative.
//
// The numbers are read as follows:
// 6 = old yin
// 7 = young yang
// 8 = young yin
// 9 = old yang
//
// We use six numbers, starting with the lowest line.
//
// We still need a way to turn the lines with their two bits of information
// into hexagrams and identify the alternative. Here are the algorithms for that.
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

// Now we write the actual interactions.
// Since this is a frontend-only app, you can totally break the interactions by
// doing unexpected things, so we'll do our best to prevent those weird things
// from happening.
const numbers = [-1, -1, -1, -1, -1, -1]; // placeholder values

function deleteNumber(idx) {
    numbers[idx] = -1;
    const inp = document.getElementById(`n${idx}`);
    inp.value = '';
}

function pushNumber(idx, number) {
    numbers[idx] = number;
    const inp = document.getElementById(`n${idx}`);
    inp.value = number;

    if (numbers.filter((n) => n > 0).length == 1) {
        document.getElementById('numbers').classList.remove('hidden');
        document.getElementById('method').disabled = true;
    } else if (numbers.every((n) => n > 0)) {
        const btn = document.getElementById('submit-consultation');
        btn.classList.remove('hidden');

        // Disable forms
        const forms = document.querySelectorAll('form.procedure');
        for (let f of forms) {
            const els = f.querySelectorAll('button, select');
            for (let el of els) {
                el.disabled = true;
            }
        }
    }
}

function submitThrow(form) {
    let data = new FormData(form);
    let number;
    if (form.name == 'three') {
        number = threeCoinsToNumber(
            data.get('first-toss') == 'tails',
            data.get('second-toss') == 'tails',
            data.get('third-toss') == 'tails');
    } else if (form.name == 'three-yarrow') {
        number = modifiedThreeCoinsToNumber(
            data.get('first-toss') == 'tails',
            data.get('second-toss') == 'tails',
            data.get('third-toss') == 'tails');
    } else if (form.name == 'two') {
        number = twoCoinsToNumber(
            data.get('first-toss') == 'tails',
            data.get('second-toss') == 'tails',
            data.get('third-toss') == 'tails',
            data.get('fourth-toss') == 'tails');
    }

    // Reset the form.
    for (let s of form.querySelectorAll('select')) {
        s.selectedIndex = 0;
        s.dispatchEvent(new Event('change'));
    }

    pushNumber(numbers.findIndex((n) => n < 0), number);
}

function submitConsultation() {
    const btn = document.getElementById('submit-consultation');
    btn.style.display = 'none'; // disappear completely from DOM

    const inps = document.querySelectorAll('#numbers-list input');
    for (let i of inps) {
        i.disabled = true;
    }

    const results = document.getElementById('results');
    results.classList.remove('hidden');

    const {hexagram, alternative} = numbersToHexagram(numbers);
    const hexagramChar = `&#${19904 + hexagram - 1};`;

    const hexSpan = document.getElementById('hexagram-result');
    hexSpan.innerHTML = `<a href="hexagram/${hexagram}.html?c=${numbers.join('')}">${hexagramChar} ${hexagram}</a>`;

    if (alternative) {
        const altChar = `&#${19904 + alternative - 1};`;
        const div = document.getElementById('alternative');
        div.classList.remove('hidden');
        const altSpan = document.getElementById('alternative-result');
        altSpan.innerHTML = `<a href="hexagram/${alternative}.html?c=${numbers.join('')}&alt=true">${altChar} ${alternative}</a>`;
    }

    // Push this consultation to the URL so you have it in history.
    // I am intentionally not making it easy to refresh the page to do another
    // consultation, because that's against the spirit.
    const url = new URL(window.location.href);
    url.searchParams.set('c', numbers.join(''));
    window.history.pushState(null, '', url.toString());
}

function setup() {
    const btn = document.getElementById('submit-consultation');
    btn.addEventListener('click', (e) => { submitConsultation(); });

    // Take over form submission.
    // Could also just listen for the click of the submit button but I'm
    // experimenting with this.
    const forms = document.querySelectorAll('form.procedure');
    for (let form of forms) {
        form.addEventListener('submit', (e) => {
            e.preventDefault();
            submitThrow(e.target);
            return false;
        });
    }

    const share = document.getElementById('share-btn');
    let timeoutId;
    share.addEventListener('click', (e) => {
        const result = document.getElementById('result');
        navigator.clipboard.writeText(`${window.location}?c=${numbers.join('')}`);
        const notif = document.getElementById('share-notif');
        notif.classList.remove('hidden');
        if (timeoutId) {
            clearTimeout(timeoutId);
            notif.classList.remove('fading');
            console.log('removed timeout');
        }
        timeoutId = setTimeout(() => {
            notif.classList.add('fading');
        }, 500);
    });

    const coinBtns = document.querySelectorAll('button.coin');
    for (let coinBtn of coinBtns) {
        coinBtn.addEventListener('click', (e) => {
            e.preventDefault();
            const s = e.target.parentElement.querySelector('select');
            s.selectedIndex = Math.floor(Math.random() * (s.options.length - 1) + 1);
            s.dispatchEvent(new Event('change'));
        });
    }

    const flipAllBtns = document.querySelectorAll('button.flip-all');
    for (let btn of flipAllBtns) {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            const ss = e.target.form.querySelectorAll('select');
            for (let s of ss) {
                s.selectedIndex = Math.floor(Math.random() * (s.options.length - 1) + 1);
                s.dispatchEvent(new Event('change'));
            }
        });
    }

    const method = document.getElementById('method');
    method.addEventListener('change', (e) => {
        const forms = document.querySelectorAll(`form.procedure`);
        for (let f of forms) {
            if (f.name == e.target.value) f.classList.add('selected');
            else f.classList.remove('selected');
        }
    });

    const selects = document.querySelectorAll('form select');
    for (let selector of selects) {
        selector.addEventListener('change', (e) => {
            // Allow form submission when all coin flips are done.
            const parentForm = e.target.form;
            const submitBtn = parentForm.querySelector('input[name=submit]');
            if (Array.from(parentForm.querySelectorAll('select')).every((s) => s.options[s.selectedIndex].value == 'heads' || s.options[s.selectedIndex].value == 'tails')) {
                submitBtn.disabled = false;
            } else {
                submitBtn.disabled = true;
            }
        });
    }

    const numberInputs = document.querySelectorAll('#numbers-list input');
    for (let inp of numberInputs) {
        inp.addEventListener('beforeinput', (e) => {
            e.preventDefault();
            const idx = parseInt(e.target.id.slice(1));
            if (e.data == '6' || e.data == '7' || e.data == '8' || e.data == '9') {
                pushNumber(idx, parseInt(e.data));
                if (idx < numbers.length-1) document.getElementById(`n${idx+1}`).focus();
            } else if (!e.data) {
                deleteNumber(idx);
                if (idx > 0) document.getElementById(`n${idx-1}`).focus();
            }
        });

    }

    // Set result depending on URL arguments.
    const paramsString = window.location.search;
    const searchParams = new URLSearchParams(paramsString);
    const c = searchParams.get("c");
    if (c && c.length == 6 && Array.from(c).every((ch) => ch == '6' || ch == '7' || ch == '8' || ch == '9')) {
        for (let i = 0; i < 6; i++) {
            pushNumber(i, parseInt(c.charAt(i)));
        }
        submitConsultation();
    }
}

if (document.readyState === 'loading') {
    document.addEventListener("DOMContentLoaded", () => {
        setup();
    });
} else {
    setup();
}

// https://www.eclecticenergies.com/iching/ is a much better version of what I
// did here, with a different (and possibly better) translation.
