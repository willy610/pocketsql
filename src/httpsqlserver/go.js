/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
function hrfpshd(params) {
    // console.log(params)
    // console.log(arguments.length)
    let parts = params.split(',')
    // console.log(parts)
    var getstr = [];
    for (p of parts) {
        // console.log(p)
        leftright = p.split('=')
        // console.log(leftright)
        getstr.push("\"" + leftright[0] + "\"" + ":" + "\"" + leftright[1] + "\"")
    }
    outparam = "\n{" + getstr.join(",") + "}\n";
    //   var getstr = '';
    //   for (var argNr = 0; argNr < arguments.length; argNr++)
    //     getstr += '&' + arguments[argNr - 0];
    //     // getstr += '&' + arguments[argNr - 0];
    // console.log(outparam)
    // console.log(getstr)
    got = rqstrsp(outparam)
    // console.log(got)
    xxx = JSON.parse(got)
    // console.log(xxx['response'])
    take_care_of_response(xxx)
    return false;
}
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
function GetXmlHttpObject() {
    var xmlHttp = null;
    try {
        xmlHttp = new XMLHttpRequest();
    }
    catch (e) {
        try {
            xmlHttp = new ActiveXObject('Msxml2.XMLHTTP');
        }
        catch (e) {
            xmlHttp = new ActiveXObject('Microsoft.XMLHTTP');
        }
    }
    return xmlHttp;
}
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
function rqstrsp(params) {

    var xmlHttp = GetXmlHttpObject();

    if (xmlHttp == null) {
        alert('Browser does not support HTTP Request');
        return true;
    }
    var url = '/ajaxsrv';
    // var param4Send = params.replace(/&amp;/g, '&');
    var param4Send = params
    var postOrGet = 'P';
    if (postOrGet == 'G') {
        xmlHttp.open('GET', url + '?' + param4Send, false);//false is synch
        xmlHttp.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');

        xmlHttp.send(null);
    }
    else {
        xmlHttp.open('POST', url, false);//false is synch
        // xmlHttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
        xmlHttp.setRequestHeader("Accept", "application/json")
        xmlHttp.setRequestHeader("Content-Type", "application/json")
        xmlHttp.send("\n" + param4Send + "\n");
    }
    if (!(xmlHttp.readyState == 4 || xmlHttp.readyState == 'complete'))
        return false;
    return xmlHttp.responseText
    //*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
}
// https://www.javascripttutorial.net/javascript-dom/javascript-insertafter/
go = function () {
    console.log("go called")
    window.onresize = function () {
        do_resize();
    };
    do_resize()
    hrfpshd('request=modules')
    hrfpshd('request=classes')
}
// document.getElementById("xyz").style.setProperty('padding-top', '10px');
// https://stackoverflow.com/questions/5191478/changing-element-style-attribute-dynamically-using-javascript

//*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
do_resize = function () {
    bottom_h = 20
    let diveders = {
        col_1: (100 - bottom_h) / 1, col_2: (100 - bottom_h) / 1, col_3: (100 - bottom_h) / 1,
        bottom: bottom_h, div_modules: (100 - bottom_h) / 2, div_classes: (100 - bottom_h) / 2
    }
    var innerWidth = window.innerWidth - 0;//22
    var innerHeight = window.innerHeight - 4;//20
    for (divid in diveders) {
        id = document.getElementById(divid);
        width = diveders[divid]
        id.style.setProperty('height', `${innerHeight * width / 100.0}px`);
    }

}
