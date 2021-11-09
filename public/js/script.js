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

function loginCheck() {
  var flag = 0;
  var loginError = document.getElementById('login_error');
  if (loginError.textContent) {
    var flag = 1;
  }
  if (flag) {
    return false;
  } else {
    return true;
  }
}

// function loginCheck() {
//   var flag = '<% flash[:login_error] %>';
//   var parentDiv = document.getElementById('login_form');
//   if (flag) {
//     let tag = document.createElement('p');
//     tag.id = 'login_error';
//     tag.innerText = '<%= flash[:login_error] %>';
//     parentDiv.appendChild(tag);
//     return false;
//   } else {
//     return true;
//   }
// }

// mypageのlist-groupをタブレット幅で横並びに変更
$(window).resize(function() {
  // windowの幅をxに代入
  var x = $(window).width();
  // windowの分岐幅をyに代入
  var y = 1024;

  if(x <= y) {
    $('#list-group').addClass('list-group-horizontal');
  }
});