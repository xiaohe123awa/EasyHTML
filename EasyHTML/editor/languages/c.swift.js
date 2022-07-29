!function(e){"use strict";function t(e){for(var t={},n=0;n<e.length;n++)t[e[n]]=!0;return t}var c=t(["_","var","let","class","enum","extension","import","protocol","struct","func","typealias","associatedtype","open","public","internal","fileprivate","private","deinit","init","new","override","self","subscript","super","convenience","dynamic","final","indirect","lazy","required","static","unowned","unowned(safe)","unowned(unsafe)","weak","as","is","break","case","continue","default","else","fallthrough","for","guard","if","in","repeat","switch","where","while","defer","return","inout","mutating","nonmutating","catch","do","rethrows","throw","throws","try","didSet","get","set","willSet","assignment","associativity","infix","left","none","operator","postfix","precedence","precedencegroup","prefix","right","Any","AnyObject","Type","dynamicType","Self","Protocol","__COLUMN__","__FILE__","__FUNCTION__","__LINE__"]),f=t(["var","let","class","enum","extension","import","protocol","struct","func","typealias","associatedtype","for"]),s=t(["true","false","nil","self","super","_"]),d=t(["Array","Bool","Character","Dictionary","Double","Float","Int","Int8","Int16","Int32","Int64","Never","Optional","Set","String","UInt8","UInt16","UInt32","UInt64","Void"]),l="+-/*%=|&<>~^?!",p=":;,.(){}[]",m=/^\-?0b[01][01_]*/,h=/^\-?0o[0-7][0-7_]*/,v=/^\-?0x[\dA-Fa-f][\dA-Fa-f_]*(?:(?:\.[\dA-Fa-f][\dA-Fa-f_]*)?[Pp]\-?\d[\d_]*)?/,_=/^\-?\d[\d_]*(?:\.\d[\d_]*)?(?:[Ee]\-?\d[\d_]*)?/,x=/^\$\d+|(`?)[_A-Za-z][_A-Za-z$0-9]*\1/,k=/^\.(?:\$\d+|(`?)[_A-Za-z][_A-Za-z$0-9]*\1)/,w=/^\#[A-Za-z]+/,y=/^@(?:\$\d+|(`?)[_A-Za-z][_A-Za-z$0-9]*\1)/;function o(e,t,n){if(e.sol()&&(t.indented=e.indentation()),e.eatSpace())return null;var i,o,r=e.peek();if("/"==r){if(e.match("//"))return e.skipToEnd(),"comment";if(e.match("/*"))return t.tokenize.push(g),g(e,t)}if(e.match(w))return"builtin";if(e.match(y))return"attribute";if(e.match(m))return"number";if(e.match(h))return"number";if(e.match(v))return"number";if(e.match(_))return"number";if(e.match(k))return"property";if(-1<l.indexOf(r))return e.next(),"operator";if(-1<p.indexOf(r))return e.next(),e.match(".."),"punctuation";if(r=e.match(/("{3}|"|')/)){var a=(i=r[0],o=1==i.length,function(e,t){for(var n,r=!1;n=e.next();)if(r){if("("==n)return t.tokenize.push(z()),"string";r=!1}else{if(e.match(i))return t.tokenize.pop(),"string";r="\\"==n}return o&&t.tokenize.pop(),"string"});return t.tokenize.push(a),a(e,t)}if(e.match(x)){var u=e.current();return d.hasOwnProperty(u)?"variable-2":s.hasOwnProperty(u)?"atom":c.hasOwnProperty(u)?(f.hasOwnProperty(u)&&(t.prev="define"),"keyword"):"define"==n?"def":"variable"}return e.next(),null}function z(){var i=0;return function(e,t,n){var r=o(e,t,n);if("punctuation"==r)if("("==e.current())++i;else if(")"==e.current()){if(0==i)return e.backUp(1),t.tokenize.pop(),t.tokenize[t.tokenize.length-1](e,t);--i}return r}}function g(e,t){for(var n;e.match(/^[^/*]+/,!0),n=e.next();)"/"===n&&e.eat("*")?t.tokenize.push(g):"*"===n&&e.eat("/")&&t.tokenize.pop();return"comment"}function a(e,t,n){this.prev=e,this.align=t,this.indented=n}e.defineMode("swift",function(i){return{startState:function(){return{prev:null,context:null,indented:0,tokenize:[]}},token:function(e,t){var n=t.prev;t.prev=null;var r=(t.tokenize[t.tokenize.length-1]||o)(e,t,n);if(r&&"comment"!=r?t.prev||(t.prev=r):t.prev=n,"punctuation"==r){var i=/[\(\[\{]|([\]\)\}])/.exec(e.current());i&&(i[1]?function(e){e.context&&(e.indented=e.context.indented,e.context=e.context.prev)}:function(e,t){var n=t.match(/^\s*($|\/[\/\*])/,!1)?null:t.column()+1;e.context=new a(e.context,n,e.indented)})(t,e)}return r},indent:function(e,t){var n=e.context;if(!n)return 0;var r=/^[\]\}\)]/.test(t);return null!=n.align?n.align-(r?1:0):n.indented+(r?0:i.indentUnit)},electricInput:/^\s*[\)\}\]]$/,lineComment:"//",blockCommentStart:"/*",blockCommentEnd:"*/",fold:"brace",closeBrackets:"()[]{}''\"\"``"}}),e.defineMIME("text/x-swift","swift")}(CodeMirror);