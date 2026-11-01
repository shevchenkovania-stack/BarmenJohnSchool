///
/// класс для работы с строками
///
class StringParser
{
  //функция проверяет если строка состоит из одной буквы
  bool isOneLetterString(String str)
  {
      //если str  это строка состоящая из одной буквы
      if (_isStringOnlyLetters(str) && str.length ==1)
      return true;

     return false;
  }
    
  //функция проверяет если стрка состоит только из букв английского алфавита
  bool _isStringOnlyLetters(String str) {
    return str.trim().isNotEmpty && str.split('').every((char) => RegExp(r'^[a-zA-Z]+$').hasMatch(char));
}
}

