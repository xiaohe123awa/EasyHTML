!function(c){var f=c.Pos;function h(e,t){for(var r=0,n=e.length;r<n;++r)t(e[r])}function r(e,t,r,n){var o=e.getCursor(),i=r(e,o);if(!/\b(?:string|comment)\b/.test(i.type)){var a=c.innerMode(e.getMode(),i.state);if("json"!==a.mode.helperType){i.state=a.state,/^[\w$_]*$/.test(i.string)?i.end>o.ch&&(i.end=o.ch,i.string=i.string.slice(0,o.ch-i.start)):i={start:o.ch,end:o.ch,string:"",state:i.state,type:"."==i.string?"property":null};for(var s=i;"property"==s.type;){if("."!=(s=r(e,f(o.line,s.start))).string)return;if(s=r(e,f(o.line,s.start)),!l)var l=[];l.push(s)}return{list:function(e,t,r,n,o){var i=[],a=e.string;function s(e){0!=e.lastIndexOf(a,0)||function(e,t){if(Array.prototype.indexOf)return-1!=e.indexOf(t);for(var r=e.length;r--;)if(e[r]===t)return!0;return!1}(i,e)||i.push(e)}function l(e,t,r,n,o){0==e.lastIndexOf(a,0)&&c(t,r,n,o)}function c(e,t,r,n){complex={5:e,3:t},r&&(complex[4]=r),n&&(complex[6]=n),i.push(complex)}if(t&&t.length){var f,u=t.pop();for(u.type&&0===u.type.indexOf("variable")?("EasyHTML"!=u.string||x("EasyHTML",e)||(s("applicationLanguage"),s("deviceLanguage")),"console"!=u.string||x("console",e)||(l("log","log(...)","log(",")"),l("warn","warn(...)","warn(",")"),l("info","info(...)","info(",")"),l("debug","debug(...)","debug(",")"),l("error","error(...)","error(",")")),n&&n.additionalContext&&(f=n.additionalContext[u.string])):"string"==u.type?f="":"atom"==u.type&&(f=1);null!=f&&t.length;)f=f[t.pop().string];null!=f&&function(e){"string"==typeof e?h(y,s):e instanceof Array?h(v,s):e instanceof Function&&h(m,s);w(e,s)}(f)}else{for(var p=e.state.localVars;p;p=p.next)s(p.name);for(var p=e.state.globalVars;p;p=p.next)s(p.name);windowProps.forEach(s),h(r,s),i.length<10&&(l("function","function() {...}","function() {\n","\n}"),l("try","try {...} catch {...}","try {\n","\n} catch(e) {\n\n}"),l("try","try {...} catch {...} finally {...}","try {\n","\n} catch(e) {\n\n} finally {\n\n}"),0=="for".lastIndexOf(a,0)&&(o._completeForCycle||(g=["i","j","k"],(d=o)._completeForCycle=function(o){var i=editor.getCursor(),a=d.getTokenAt(d.getCursor());d.operation(function(){for(var e=-1;;){var t=g[++e]||"index"+e;if(!x(t,a)){if(o){var r="l";if(e&&(r+=e),x(r,a))continue;editor.replaceRange("for(var "+t+" = 0, "+r+" = ",i,i);var n=editor.getCursor();editor.replaceRange(".length; "+t+" < "+r+"; "+t+"++) {\n\n}",n,n),editor.setCursor(n)}else{editor.replaceRange("for(var "+t+" = 0; "+t+" < ",i,i);var n=editor.getCursor();editor.replaceRange("; "+t+"++) {\n\n}",n,n),editor.setCursor(n)}editor.indentLine(i.line,"smart",!0),editor.indentLine(i.line+1,"smart",!0),editor.indentLine(i.line+2,"smart",!0);break}}})}),c("for(i < array.length) {...}","","","editor._completeForCycle(1)"),c("for(i < ...) {...}","","","editor._completeForCycle(0)")),l("setTimeout","setTimeout(...)","setTimeout(function(){\n","\n}, 10);"),l("setInterval","setInterval(...)","setInterval(function(){\n","\n}, 10);"),l("if","if ...","if(cond",") {\n\n}"),l("if","if ... else ...","if(cond",") {\n\n} else {\n\n}"),l("while","while (...) {...}","while(cond",") {\n\n}"),l("do","do {...} while (...)","do {\n\n} while(cond",");"))}var d,g;return l("forEach","forEach","forEach(function(element){\n","\n})"),i}(i,l,t,n,e),from:f(o.line,i.start),to:f(o.line,i.end)}}}}function n(e,t){var r=e.getTokenAt(t);return t.ch==r.start+1&&"."==r.string.charAt(0)?(r.end=r.start,r.string=".",r.type="property"):/^\.[\w$_]*$/.test(r.string)&&(r.type="property",r.start++,r.string=r.string.replace(/\./,"")),r}c.registerHelper("hint","javascript",function(e,t){return r(e,o,function(e,t){return e.getTokenAt(t)},t)}),c.registerHelper("hint","coffeescript",function(e,t){return r(e,i,n,t)});var y="charAt charCodeAt indexOf lastIndexOf substring substr slice trim trimLeft trimRight toUpperCase toLowerCase split concat match replace search".split(" "),v="length concat join splice push pop shift unshift slice reverse sort indexOf lastIndexOf every some filter forEach map reduce reduceRight ".split(" "),m="prototype apply call bind".split(" "),o="break case catch class const continue debugger default delete else export extends false finally for function if in import instanceof new null return super switch this throw true typeof var void with yield".split(" "),i="and break catch class continue delete else extends false finally for if in instanceof isnt new no not null of off on or return switch then throw true typeof until void with yes".split(" ");function x(e,t){if(t.state.context)for(var r=t.state.context;r;r=r.prev)for(var n=r.vars;n;n=n.next)if(n.name==e)return!0;for(n=t.state.localVars;n;n=n.next)if(n.name==e)return!0;for(n=t.state.globalVars;n;n=n.next)if(n.name==e)return!0;return!1}function w(e,t){if(!Object.getOwnPropertyNames||!Object.getPrototypeOf){for(var r in e)t(r)}else{for(var n=e;n;n=Object.getPrototypeOf(n))Object.getOwnPropertyNames(n).forEach(t)}}}(CodeMirror);