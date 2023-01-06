public class IFv2_DependentPicklist {
    public Map<String,Integer> AlphaNumCharCodes {get;set;}
    public Map<String, Integer> Base64CharCodes { get; set; }
    public IFv2_DependentPicklist(){
        LoadCharCodes();
    }
    //Method loads the char codes
    private void LoadCharCodes(){ 
        AlphaNumCharCodes = new Map<String,Integer>{
            'A'=>65,'B'=>66,'C'=>67,'D'=>68,'E'=>69,'F'=>70,'G'=>71,'H'=>72,'I'=>73,'J'=>74,
                'K'=>75,'L'=>76,'M'=>77,'N'=>78,'O'=>79,'P'=>80,'Q'=>81,'R'=>82,'S'=>83,'T'=>84,
                'U'=>85,'V'=> 86,'W'=>87,'X'=>88,'Y'=>89,'Z'=>90
                };
                    Base64CharCodes = new Map<String, Integer>();
        //lower case
        Set<String> pUpperCase = AlphaNumCharCodes.keySet();
        for(String pKey : pUpperCase){
            //the difference between upper case and lower case is 32
            AlphaNumCharCodes.put(pKey.toLowerCase(),AlphaNumCharCodes.get(pKey)+32);
            //Base 64 alpha starts from 0 (The ascii charcodes started from 65)
            Base64CharCodes.put(pKey,AlphaNumCharCodes.get(pKey) - 65);
            Base64CharCodes.put(pKey.toLowerCase(),AlphaNumCharCodes.get(pKey) - (65) + 26);
        }
        
        //numerics
        for (Integer i=0; i<=9; i++){
            AlphaNumCharCodes.put(string.valueOf(i),i+48);
            //base 64 numeric starts from 52
            Base64CharCodes.put(string.valueOf(i), i + 52);
        }
        Base64CharCodes.put('+',62);/*Added by anoop*/
        Base64CharCodes.put('/',63);/*Added by anoop*/
        system.debug('AlphaNumCharCodes:'+AlphaNumCharCodes);
        system.debug('Base64CharCodes:'+Base64CharCodes);
    }
    public List<Integer> testBits(String pValidFor,List<Integer> nList){
        system.debug('nList:'+nList);
        system.debug('nList size:'+nList.size());
        system.debug('pValidFor:'+pValidFor);
        List<Integer> results = new List<Integer>();
        
        //the list of bytes (not derived from n)
        List<Integer> pBytes = new List<Integer>();
        //multiply by 6 since base 64 uses 6 bits (not derived form n)
        Integer bytesBeingUsed = (pValidFor.length() * 6)/8;
        //will be used to hold the full decimal value (not derived from n)
        Long pFullValue = 0;
        //must be more than 1 byte
        if (bytesBeingUsed <= 1)
            return results;
        //get the base64bytes
        for(Integer i=0;i<pValidFor.length();i++){
            //get currenct character value
            pBytes.Add((Base64CharCodes.get((pValidFor.Substring(i, i+1)))));
        }
        system.debug('pBytes:'+pBytes);
        list<String> bitStream = new list<String>();
        //prepare binary list for pBytes
        for(Integer i = 0; i < pBytes.size(); i++) {
            bitStream.addAll(intToBinary(pBytes[i],6));
        }
        system.debug('bitStream:'+bitStream);
        //Iterate over the binary list and return positions of 1
        for(Integer i = 0; i < bitStream.size(); i++){
            if(bitStream[i]=='1'){
                results.add(i);
            }
        }
        return results;
    }
    
    public static list<String> intToBinary(Integer numb,Integer size){
        list<String>Bits = new list<String>();
        list<String>retBits = new list<String>();
        map<Integer,String> bitMap = new map<Integer,String>();
        Integer num = numb;
        Integer pow=0;
        while(num>0){
            Bits.add(String.valueOf(math.mod(num,2)));
            num/=2;
        }
        for(Integer i=Bits.size();i<size;i++){
            Bits.add('0');
        }
        for(Integer i=Bits.size()-1;i>=0;i--){
            retBits.add(Bits[i]);
        }
        system.debug(String.join(retBits,''));
        return retBits;
    }
}