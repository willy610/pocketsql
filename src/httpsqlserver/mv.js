
// 	"<img src='./pics/open.gif' border='0' /></a>\n" 

function take_care_of_response(response) {
    switch (response['response']) {
        case 'modules':
            at = document.getElementById('div_modules');
            colindx_module=response['col_names'].indexOf("module")
            wri = []
            for (const element of response['rows']) {
                the_module=element[colindx_module]
                wri.push(`<a href="javascript:hrfpshd('request=module,module=${the_module}');">${the_module}</a>`);
            }
            // at.innerHTML = `<h4>Modules:</h4>` + wri.join('<br>')
            at.innerHTML =  wri.join('<br>')
            break;
        case 'module':
            at = document.getElementById('div_one_module');
            wri = []
            for (const element of response['names']) {
                 wri.push(`<a href="#" onclick="javascript:alert('Manage -${element}- in a module');return false;">${element}</a>`);
            }
            the_module_name =response['the_module_name']
            var the_text = document.createElement("text");
            a_deleter = `<button type="button" onclick="javascript:bort('div_one_module_${the_module_name}'); ">Close</button><br>`;
            the_text.innerHTML = `<div id="div_one_module_${the_module_name}">
            <h4>Module: ${the_module_name}</h4>` + a_deleter + wri.join('<br>') + "</div>"
            at.appendChild(the_text);
            break;
        case 'classes':
            at = document.getElementById('div_classes');
            colindx_filename=response['col_names'].indexOf("class")
            wri = []
            for (const element of response['rows']) {
                the_class=element[colindx_filename]
                wri.push(`<a href="javascript:hrfpshd('request=class,class=${the_class}');">${the_class}</a>`);
            }
            at.innerHTML = `<h4>Classes:</h4>` + wri.join('<br>')
            break;
        case 'class':
            at = document.getElementById('div_one_class');
            the_class_name =response['the_class_name']
            wri = []
                for (const method of response['rows']) {
                    // wri.push(`<a href="javascript:hrfpshd('request=class,class=${method}');">${method}</a>`);
                    wri.push(`<a href="javascript:show_method('${the_class_name}','${method}');">${method}</a>`);
                }
            var the_text = document.createElement("text");
            a_deleter = `<button type="button" onclick="javascript:bort('div_one_class_${the_class_name}'); ">Close</button><br>`;

            the_text.innerHTML = `<div id="div_one_class_${the_class_name}">
            <h4>Methods in Class: ${the_class_name}</h4>` + a_deleter + wri.join('<br>') + "</div>"
            at.appendChild(the_text);
            break;
            case 'FAIL':
                break;
        default: console.log(`Sorry, we are out of ${response['response']}.`);
    }
}
function bort(vad) {
    at = document.getElementById(vad);
    at.remove();
}
function show_method(klass,metod) {
    console.log(klass)
    console.log(metod)
    at = document.getElementById('col_3');
    var the_text = document.createElement("text");
    hold_it = `<div id=${klass}_${metod}><fieldset><legend>Edit method</legend>
    <table>
    <tr><td><b>${klass}::</b></td><td><b>${metod}</b></td></tr>
    <tr>
        <td><label for='param'>Params:</label></td>
        <td><input type='text' id='param' name='param' value='par1'></td>
        <td><input size="23" type='text' id='inf_param' name='inf_param' disabled value='(infered) par1 : String'></td>
        <td><button onclick="javascript:alert('Increment compile -${metod}- Params');return false;">Compile</button></td>
    </tr>
    <tr>
        <td><label for='return'>Returns:</label></td>
        <td><input type='text' id='return' name='return'></td>
        <td><input  size="22" type='text' id='inf_return' name='inf_return' disabled value='(infered) String | Nil'></td>
        <td><button onclick="javascript:alert('Increment compile -${metod}- Returns');return false;">Compile</button></td>
    </tr>Onr 
    <tr>
        <td><label for='body'>body:</label></td>
        <td colspan='3'><textarea id='body' name='body' rows='5' cols='50' style=resize:auto;vertical-align:top;'>
if par1.size > 0
    return par1
else
    return nil
end</textarea></td>
    </tr>
    <tr>
        <td><button onclick="javascript:bort('${klass}_${metod}');">Close</button></td>
        <td><button onclick="javascript:alert('Increment compile -${metod}- body');return false;">Compile</button></td>
        <td style="text-align:right;"><button onclick="javascript:alert('Link an image');return false;">Link Image</button></td>
    </tr>
    </table></fieldset><div>`
    the_text.innerHTML = hold_it
    at.appendChild(the_text);
    // at = document.getElementById(vad);
    // at.remove();
}
function querystatment() {
    stm = document.getElementById('querystatment').value;
    stm = stm.replaceAll('\n', '\\n')
    txt = rqstrsp(`{"request":"query","stm":"${stm}"}`)
    txt = txt.replaceAll('\n', '\\n')
    xxx = JSON.parse(txt)

    dest = document.getElementById('queryresult');
    // dest.innerHTML = '<pre><code>' + xxx['as_code'].replaceAll('&', '\n') + '</code></pre>'
    dest.innerHTML = '<pre><code>' + xxx['as_code'] + '</code></pre>'
    return false
}
