const fratricide = li => {
    console.log('fratricide:', li);
    let del = false;
    let blocker = false;
    if (li.tagName == 'SPAN') {
        if (li.classList.contains('replace')) {
            li.firstChild.data = li.getAttribute('data-replace-with');
        }
        if (li.classList.contains('delete')) {
            del = true;
        }
        if (li.classList.contains('blocker')) {
            blocker = true;
        }
        li = li.parentElement;
    }
    
    let eldest = li.firstElementChild;
    if (eldest) {
      if (eldest.tagName == 'SPAN') {
          if (eldest.classList.contains('replace')) {
              eldest.firstChild.data = eldest.getAttribute('data-replace-with');
          }
          if (eldest.classList.contains('delete')) {
              del = true;
          }
          if (eldest.classList.contains('blocker')) {
              blocker = true;
          }
      }
    }

     if (li.classList.contains('chosen')) {
         console.log('stopping early:', li);
         return;
     }

    const elId = li.id;
    const tmpId = 'murderer';
    li.id = tmpId;

    const parent = li.parentElement;
    const children = parent.children;
    let killList = [];
    for (let child of children) {
       if (child.id !== tmpId && !blocker && !child.classList.contains('unblocker')) {
          killList.push(child);
       }
    }
    for (let child of killList) {
      child.remove(); // sacrifice the lesser children
    }

    li.id = elId;
    li.classList.add('chosen');

    const ul = li.querySelector('ul');
    console.log('li query selector:', li, ul);
    if (ul) {
      for (let child of ul.children) {
        child.classList.remove('hidden');
      }
    } else {
        // Leaf node, so unblock nearest blocker.
        let blocker = li.closest('li:has(span.blocker)');
        if (blocker) {
            blocker.firstChild.classList.remove('blocker');
            blocker.classList.add('unblocker');
            let next = blocker.nextElementSibling;
            if (next) {
              next.classList.remove('hidden');
            }
        }
    }
    if (del) {
        let container = parent.parentElement;
        parent.remove();
        if (ul) {
          container.append(ul);
        }
    }
};

const bullets = document.querySelectorAll('li');
for (let bull of bullets) {
    bull.onclick = (e) => {fratricide(e.target)};
    
    const ul = bull.querySelector('ul');
    if (ul) {
      for (let child of ul.children) {
        child.classList.add('hidden');
      }
    } else {
      bull.classList.add('leaf');
    }
}

const ref = document.getElementById('alert');
ref.addEventListener('click', (e) => {
    if (!confirm('Are you sure? Your process will be lost.')) e.preventDefault();
    else {window.location = window.location;}
}, false);
