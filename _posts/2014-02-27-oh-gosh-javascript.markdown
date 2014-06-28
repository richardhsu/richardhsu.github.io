---
layout: post
comments: true
title: "Oh Gosh Javascript"
date: 2014-02-27 19:35:00
tags: [Javascript, Tips, Programming]
---

Javascript is a funny language. I rarely find myself going "oh that makes sense"
, but then again when I think about all the rules and structures of the
language, it does make sense in that context ... Of course, I'm not justifying
the language decisions, just that based on the design of the language, the
outcomes make sense.

<!--more-->

Recently I ran into the issue of an event handler that didn't exist even though
it was clearly defined! An example of the code would be as such:

```javascript
var div = document.getElementById(element_id),
    button = document.createElement("button");
button.innerHTML = "Click Me";
button.onclick = function (event) {
  alert("Hello");
};
div.appendChild(div);
```

This is all fine and dandy and the event handler exists, but if we do something
afterward like:

```javascript
div.innerHTML += "<p>More text inside the div.</p>";
```

The event handler on the button disappears! This actually makes sense if you
understand `innerHTML`. I actually didn't know about this and figured
`innerHTML` was the structure and you could easily modify with appending, but
I didn't think that it caused a reparsing of the elements on the page. In effect
it is because the line becomes:

```javascript
div.innerHTML = div.innerHTML + "<p>More text inside the div.</p>";
```

Therefore since the `onclick` event is defined in Javascript and doesn't carry
over in the HTML then when a reparsing is done the event disappears.

> Oh the mysteries of Javascript, how I have much to learn.

I felt really stupid afterward, but hopefully now you know or you just think
I'm stupid too. Oh well, as long as I'm learning everyday!
