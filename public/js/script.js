// signupモーダルでvalueがblankの場合にアラートを表示する
function formCheck() {
  var flag = 0;
  if (document.signup.name.value == "") {
    flag = 1;
    document.getElementById('blank_name').style.display = "block";
  } else {
    document.getElementById('blank_name').style.display = "none";
  }
  if (document.signup.email.value == "") {
    flag = 1;
    document.getElementById('blank_email').style.display = "block";
  } else {
    document.getElementById('blank_email').style.display = "none";
  }
  if (document.signup.password.value == "") {
    flag = 1;
    document.getElementById('blank_password').style.display = "block";
  } else {
    document.getElementById('blank_password').style.display = "none";
  }
  if (flag) {
    return false;
  } else {
    return true;
  }
}