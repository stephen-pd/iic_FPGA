/*
 * @FilePath       : \sr\uart\uart.c
 * @Author         : stephenpd stephenpd@163.com
 * @CreateDate     : 2022-08-31 22:52:50
 * @LastEditors    : stephenpd stephenpd@163.com
 * @LastEditTime   : 2022-09-02 11:23:10
 * @Description    : 
 *                  
 * 
 *                  
 * 
 * Rev 1.0    
 *                  
 * 
 */


/*
int main(){
    long int data ;
    int i;
    char data2char[8];
    data=0x0000afcc;
    for(i=0 ;i<8 ;i++){
        data2char[i] = data%16;
        if(data2char[i]<0 || data2char[i]>9){
            data2char[i] = data2char[i] + 'a' - 10;
        }else  {
            data2char[i] = data2char[i] + '0';
        }
        data = data>>4;
    }
    for(i=0 ;i<8 ;i++){
        printf("%c" ,data2char[7-i]);
    }

}
*/

long int str2int (const char *str){
    long int temp = 0;
    const char *ptr = str;
    while(*str != '\0'){
        if ((*str < '0') || (*str > '9')){//if not number
            break;
        } else{
            temp = temp*10 + (*str - '0');
            str++;//move to next char
        }
    }
    return temp;
}

int main(){

    char a[40]="0123456789ABCDEF";//用一个数组存储十六进制数
    char uartcmd[8] = "102424";
    long int char2str;
    int cnt=0 ;
    //uartcmd = "1024";
    char2str = str2int(uartcmd);
    printf("%ld",char2str);
    while(char2str!=0)
	{
		b[++cnt]=a[char2str%16];//这里cnt从1开始
		char2str=char2str/16;
	 } 

}