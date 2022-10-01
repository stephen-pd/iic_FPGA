(
    function main() {
        var str = receive.get();          //Read the Received string
        receive.write(str);               //Prints the received characters
        receive.write(" -> ", "red");     //Print the arrow
        var buf = StrToBytes(str);        //Turn the received hex string into an array.
        var val = BufToValue(buf, 7, 2);  // CO Turn the array into integers by index and length
        var val2 = BufToValue(buf, 9, 2); // HC
        receive.write(val + " ", "Green");//Print the converted integer
        receive.write(val2, "DarkRed");
        chart.write("HC=" + val + "\n");  //Draw to waveform interface. The name is HC
        chart.write("NO=" + val2 + "\n"); //Draw to waveform interface. The name is NO
        receive.write("\r\n");            //Print line breaks for easy observation.
        return;
    }
)()
 
// Turn the data in buf into an integer.
// buf array
// index : The starting position in Bytes
// len : Contains the number of bytes
function BytesToValue(buf, index, len) {
    var val = 0;
    for (var i = 0; i < len; i++) {
        val = val << 8;
        val = val + buf[i + index];
    }
    return val;
}
//Turn the received hex string into an int array.
function StrToBytes(str) {
    var index = 0;
    var buf = new Array;
    for (var i = 0; i < str.length; i++) {
        while (str[i] == "«" || str[i] == " ") { //Remove useless characters
            if (i < str.length)
                i++;
        }
        buf[index] = parseInt("0x" + str[i] + str[i + 1]);// Turn the string into a number.
        index++;
        i += 2;
    }
    return buf;
}