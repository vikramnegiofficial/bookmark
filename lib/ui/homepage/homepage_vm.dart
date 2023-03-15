import 'dart:convert';
import 'dart:io';
import 'package:bookmark/data.dart';
import 'package:bookmark/model/book.dart';
import 'package:bookmark/model/book_model.dart';
import 'package:bookmark/model/cart_model.dart';
import 'package:bookmark/model/user_model.dart';
import 'package:bookmark/ui/add_book/add_book_vm.dart';
import 'package:bookmark/ui/book_details_page/new_details.dart';
import 'package:bookmark/ui/main/order_page.dart';
import 'package:bookmark/ui/profile/profileVM.dart';
import 'package:bookmark/utils/cupertinoDialogBox.dart';
import 'package:bookmark/utils/login_first_dialog.dart';
import 'package:bookmark/utils/shared_prefer.dart';
import 'package:bookmark/constants/api_constants.dart';
import 'package:bookmark/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SuggestionItemCardModel {}

class Option {
  Option({required this.name, required this.icon, this.selected = false});
  final String name;
  bool selected = false;
  final IconData icon;
}

class DiningVM extends GetxController {
  Map<String, String> currentUserData = {};

  get fw => null;
  void getCurrentUSerData() async {
    currentUserData = {
      "name": await SharedPrefs.getString("name") ?? "",
      "userName": await SharedPrefs.getString("userName") ?? "",
      "email": await SharedPrefs.getString("email") ?? "",
      "image": await SharedPrefs.getString("image") ?? "",
      "address": await SharedPrefs.getString("address") ?? "",
      // "city": await SharedPrefs.getString("city") ?? "",
      "id": await SharedPrefs.getString("id") ?? "",
    };
  }

  List<BookModel> bookList = [];
  List<BookModel> userBookmarks = [];
  // List<Userbook> userBook = [];
  List<BookModel> userBook = [];
  List<BookModel> collectionBooks = [];
  TextEditingController searchController = TextEditingController();
  TextEditingController noOfDaysController = TextEditingController();

  bool showMore = false;
  List<BookModel> highestRatingBook = [];
  List<BookModel> relatedBookList = [];
  List<BookModel> suggestionItemCard = [];
  List<BookModel> featuredBooks = [];
  List<BookModel> selectedGenerBooks = [];
  List<Language> languageList = [];
  List<BookModel> likedBookList = [];
  List<CartModel> selectedCartList = [];
  final infiniteScrollController = ScrollController();
  bool loadMore = false;
  bool loadMoreLoading = false;
  bool isGenerSelected = false;
  bool isUserLoginedIn = false;
  bool afterPaymentLoader = false;
  bool loader = false;
  bool isError = false;
  bool showCartSelectOption = false;
  String userCity = "";
  String userState = "";
  void loginFunctionality() async {
    String userAddress = (await SharedPrefs.getString("address"))!;
    Map<String, dynamic> map = jsonDecode(userAddress);
    userCity = map["city"] ?? "";
    userState = map["state"] ?? "";
    // print(Address.fromJson(userAddress));
    print("usercity : $userCity");
    update();
  }

  Future<void>? isUserLoginedInFun() async {
    isUserLoginedIn =
        (await SharedPrefs.getString("id")) != null ? true : false;

    update();
  }

  void logout() async {
    await SharedPrefs.clearPrefs();
    await SharedPrefs.setBool("newDevice", false);
    isUserLoginedIn = false;
    update();
    await getBookOfSelectedGenre("Horror");
    getAllBooks();
  }

  void tapOnCategoriesSelected() {
    isGenerSelected = true;
    Future.delayed(const Duration(seconds: 1), () {
      isGenerSelected = false;
      update();
    });
    update();
  }

  List<Option> options = [
    Option(name: 'Novel', icon: Icons.book),
    Option(name: 'Romance', icon: Icons.favorite),
    Option(name: 'Thriller', icon: Icons.cut),
    Option(name: 'Horror', icon: Icons.self_improvement, selected: true),
    Option(name: 'Fiction', icon: Icons.science),
  ];

  List<BookModel> list = [];

  void listScrollListener() {
    infiniteScrollController.addListener(() {
      if (infiniteScrollController.position.maxScrollExtent ==
          infiniteScrollController.offset) {
        // fetchData();
        list.addAll(collectionBooks);
        print("added by scrollcontroller");
        update();
      }
    });
  }

  @override
  void onInit() async {
    loginFunctionality();
    isUserLoginedInFun();
    getCurrentUSerData();
    // readJsonFile();
    getGenres();
    // print("chala");
    await getBookOfSelectedGenre("Horror");
    // print("nhi chala");
    getAllBooks();
    getUserBooks();
    // getSingleBook("63ce4da2aaf99f75cdada856");
    // suggestionBookCard = bookData2.sublist(0, 3);
    // getSuggestionItem();
    listScrollListener();
    super.onInit();
  }

  bool deleteMultipleLiked = false;
  List<BookModel> removeLikedBookList = [];
  void removeLikedFood() {
    for (var element in removeLikedBookList) {
      removeLikeItem(element);
    }
  }

  void removeLikeItem(BookModel item) {
    if (suggestionItemCard.contains(item)) {
      debugPrint("sugggggggggg");
      Book findedItem =
          suggestionBookCard.firstWhere((element) => element.id == item.id);
      findedItem.isLiked = false;
    }
    if (bookList.contains(item)) {
      debugPrint("fod data");
      BookModel findedItem =
          bookList.firstWhere((element) => element.id == item.id);
      findedItem.isLiked = false;
    }
    likedBookList.remove(item);
    update();
  }

  List<Book> suggestionBookCard = [];

  double totalPrice = 0;

  bool isSingleBookPurchase = false;
  BookModel? singleBookPurchase;
  Fees singleBookFees = Fees(rentalCharge: 0, grandtotal: 0);

  List<CartModel> cartfoods = [];
  void purchaseSingleBook(BookModel book) {
    isSingleBookPurchase = true;
    singleBookPurchase = book;
    cartfoods.clear();
    cartfoods.add(CartModel(book: book, noOfDays: 3, id: "1123456543"));
    update();
  }

  Fees variousFees = Fees(
      deliveryFees: 0,
      internetHandlingFees: 0,
      serviceFees: 0,
      grandtotal: 0,
      rentalCharge: 0);
  List<Map<String, double>> variousFeesList = [];
  bool isBookInCartList(BookModel book) {
    return cartfoods.contains(book);
  }

  // Dynamic Contect
  bool errorOccurUserBook = false;
  bool errorOccurSingleBook = false;

  bool isGetBookLoading = false;
  bool homeScreenLoading = false;
  List<BookModel> booksList = [];
  List<BookModel> genreBooksList = [];
  List<Genre> genreList = [];
  BookModel? Singlebooks;
  void loadGenreList() {
    isGenerSelected = !isGenerSelected;
    update();
  }

  Future<void> getBookOfSelectedGenre(String generQ) async {
    loadGenreList();
    var id = "";
    print("lllllllllllllllllll");
    if (genreList.length > 0) {
      print(genreList[0].genre);
    }
    if (generQ == "Horror") {
      id = "63e11722075a28576731a379";
    } else {
      for (var gener in genreList) {
        if (generQ.toLowerCase() == gener.genre.toLowerCase()) {
          id = gener.id;
        }
      }
    }
    print("id : $id");
    // print("gener id : $id");
    callAndErrorHendling(
        callback: (data) {
          List new_data = [];
          print("select genre data : $data");
          if (data["msg"]["result"] == null) {
          } else if (data["msg"]["result"][0]["uploadedBy"].runtimeType ==
              String) {
            new_data = data["msg"]["result"];
          } else {
            for (var item in data["msg"]["result"]) {
              var uid = item["uploadedBy"]["_id"];
              item["uploadedBy"] = uid;
              new_data.add(item);
            }
          }
          // print("new gener data : $new_data");
          genreBooksList =
              new_data.map<BookModel>((e) => BookModel.fromMap(e)).toList();
          update();
        },
        errorOccurFunction: () {
          print("error occur");
          update();
        },
        url: isUserLoginedIn
            ? "${base_url}book?genre=$id&limit=5&state=$userState&city=$userCity"
            : "${base_url}book?genre=$id&limit=5",
        method: "get",
        body: {});
    loadGenreList();
  }

  Future<void> getBooksByQuery(String query, String type) async {
    try {
      isGetBookLoading = true;
      update();
      String id = "";
      if (type == "genre") {
        for (var genre in genreList) {
          if (genre.genre == query) {
            id = genre.id;
          }
        }
      } else if (type == "language") {
        for (var language in AddBookVM().languageList) {
          if (language.language == query) {
            id = language.id;
          }
        }
      }
      final response = await http.get(
        Uri.parse("${base_url}book/get-books-byproperty?$query=$id"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        genreBooksList = data['msg']["result"]
            .map<BookModel>((e) => BookModel.fromJson(e))
            .toList();
        isGetBookLoading = false;
        update();
      } else {
        isGetBookLoading = false;
        update();
      }
    } catch (e) {
      isGetBookLoading = false;
      update();
    }
  }

  getSingleBook(id) async {
    await callAndErrorHendling(
        errorOccurFunction: () {
          errorOccurSingleBook = true;
          update();
        },
        callback: (data) {
          Singlebooks = BookModel.fromMap(data["msg"]);
          update();
        },
        url: "https://test-bk-api.onrender.com/book/get-single-book/${id}",
        method: "get",
        body: {});
    print("BookModel : ${Singlebooks!.bookName}");
  }

  getAllBooks() async {
    homeScreenLoading = true;
    update();
    await callAndErrorHendling(
        errorOccurFunction: () {},
        callback: (data) {
          print("data get all books : ${data}");
          List new_data = [];
          // for (var item in data["msg"]["result"]) {
          //   // var id = item["uploadedBy"]["_id"];
          //   // item["uploadedBy"] = id;
          //   new_data.add(item);
          // }
          // print("all books new Data -- ${data}");
          List bookDataList =
              data["msg"]["result"].map((e) => BookModel.fromMap(e)).toList();

          booksList = List<BookModel>.from(bookDataList);
          list = List<BookModel>.from(bookDataList);
          print("list get all : ${list[0].bookName}");
          print("email get all : ${booksList[0].bookName}");
          collectionBooks =
              booksList.length > 4 ? booksList.sublist(0, 4) : booksList;
          featuredBooks = booksList.length > 4
              ? booksList
                  .where((element) => element.rentPerDay! > 15)
                  .toList()
                  .sublist(0, 4)
              : booksList;
          print("dddddddddddddddddd");
          // print(bookList.length);
          // print(featuredBooks.length);
          // print(collectionBooks.length);
          update();
        },
        url: isUserLoginedIn
            ? "${base_url}book?state=$userState&city=$userCity"
            : "${base_url}book",
        method: "get",
        body: {},
        loader: true,
        error: "Invalid Credentials");
    // print("BookModel : ${booksList[0]}");
    // isGetBookLoading = true;
    // update();
    // try {
    //   print("Calling get book api");
    //   final response = await http.get(
    //     Uri.parse("https://test-bk-api.onrender.com/book/get-books"),
    //   );
    //   if (response != null && (response.statusCode == 200)) {
    //     Map<String, dynamic> data = jsonDecode(response.body);
    //     print(data);
    //     if (data["success"]) {
    //       List bookDataList =
    //           data["msg"]["result"].map((e) => BookModel.fromMap(e)).toList();
    //       print("email : ${bookDataList[0]}");
    //       booksList = List<BookModel>.from(bookDataList);
    //     } else {
    //       Get.snackbar("Error", "Invalid Credentials");
    //     }
    //   } else {
    //     print(response.body);
    //     Get.snackbar("Error", "Invalid Credentials");
    //   }
    // } catch (e) {
    //   Get.snackbar("Error", "Something went wrong");
    //   print(e.toString());
    // }
    // isGetBookLoading = false;
    homeScreenLoading = false;
    update();
  }

  List<String> tempSearchList = [];
  List<String> searchHistroyList = [
    "The History of Tom Jones, a Foundling",
    "The hidden hindu",
  ];

  Future<void> getHistory() async {
    try {
      // var res = await http.get(
      //     Uri.parse("https://test-bk-api.onrender.com/book/get-history"));
      // var data = jsonDecode(res.body);
      // if (data["success"]) {
      //   historyList = data["msg"]["result"]
      //       .map<HistoryModel>((e) => HistoryModel.fromMap(e))
      //       .toList();
      //   update();
      // }
    } catch (e) {
      print("get history catch : ${e.toString()}");
    }
  }

  void userTapForSearch() {
    tempSearchList = searchHistroyList;
    update();
  }

  BookModel? selectedSearchBook;

  void runSearch(String value) {
    List<String> result = [];
    if (value.isEmpty) {
      result = searchHistroyList;
    } else {
      for (var bookName in booksList
          .where((e) => e.bookName.toLowerCase().contains(value.toLowerCase()))
          .toList()) {
        result.add(bookName.bookName);
      }
    }
    tempSearchList = result;
    update();
  }

  void userTapOnSearch(String value) {
    selectedSearchBook = booksList
        .where((e) => e.bookName.toLowerCase() == value.toLowerCase())
        .toList()[0];
    update();
    Get.to(() => BookDetails(bookModel: selectedSearchBook!));
  }

  bool genreLoader = false;
  void getGenres() async {
    genreLoader = true;
    update();
    try {
      // var res = await http.get(Uri.parse("${base_url}genre/get-genres"));
      var res = await http
          .get(Uri.parse("https://test-bk-api.onrender.com/genre/get-genres"));
      var lang_data = jsonDecode(res.body);
      // print("genre data : ${lang_data}");
      genreList = lang_data["msg"]["result"]
          .map<Genre>((e) => Genre.fromMap(e))
          .toList();

      update();
    } catch (err) {
      print("Genre catch err : ${err}");
    }
    genreLoader = false;
    update();
  }

  void validateAndSaveToCart(BookModel book) async {
    if (!isUserLoginedIn) {
      LoginFirstDialog(Get.context);
      return;
    } else if (userCity != book.city || userState != book.state) {
      showDialogBox(Get.context!, "Can't order Book",
          "This Book is From Different city or state", true);
    } else if (cartfoods.isNotEmpty &&
        book.uploadedBy != cartfoods[0].book.uploadedBy) {
      CupertinoDialogBox(Get.context, () async {
        String token = (await SharedPrefs.getString("token"))!;
        var res = await http.delete(
          Uri.parse("${base_url}user/cart"),
          headers: {
            "authorization": "Bearer $token",
          },
        );
        Get.back();
        print(res.body);
        Map map = jsonDecode(res.body);
        if (map["success"]) {
          sevetoCart(book);
        }
      }, "Replace Cart Item?",
          "Our Cart contains books from Different user. Do you want to discard the selection and add this user book?");
    } else {
      sevetoCart(book);
    }
  }

  void sevetoCart(BookModel book, {bool increaseQty = false}) async {
    // genreLoader = true;
    if (!isUserLoginedIn) {
      LoginFirstDialog(Get.context);
      return;
    }
    update();
    try {
      String userId = (await SharedPrefs.getString("userId")) ?? "";
      if (!increaseQty) {
        cartfoods.add(CartModel(id: userId, book: book, noOfDays: 30));
      }
      update();
      String token = (await SharedPrefs.getString("token"))!;
      var res = await http.post(
        Uri.parse("${base_url}user/cart/${book.id}"),
        headers: {
          "authorization": "Bearer $token",
        },
        body: {"bookId": book.id, "noOfDays": "3"},
      );
      print("sevetoCart : ${res.body} && ${res.statusCode}");
      if (!increaseQty) {
        showSnackBar(Get.context!, "Added to cart", false);
      }
      await getUserBookmarked();
      update();
    } catch (err) {
      print("Bookmark catch err : ${err}");
    }
    // genreLoader = false;
    update();
  }

  void decreaseCartItemQty(CartModel cart) async {
    cart.noOfDays--;
    if (cart.noOfDays <= 0) {
      cartfoods.remove(cart);
    }
    update();
    String token = (await SharedPrefs.getString("token"))!;
    var res = await http.post(Uri.parse("${base_url}user/cart"), headers: {
      "authorization": "Bearer $token",
    }, body: {
      "bookIdArray": cart.book.id,
      "deleteItem": "1"
    });
    print("decreaseCartItemQty : ${res.body} && ${res.statusCode}");
    if (res.statusCode != 201 || !jsonDecode(res.body)["success"]) {
      showSnackBar(Get.context!, "Something went wrong", true);
      cart.noOfDays++;
      cartfoods.add(cart);
    }
    update();
  }

  void increaseCartItemQty(CartModel cart) async {
    cart.noOfDays++;
    sevetoCart(cart.book, increaseQty: true);
  }

  void deleteSelectedCartItems() async {
    // genreLoader = true;
    update();
    print("delete api called");
    String bookIdString = "";
    for (var i = 0; i < selectedCartList.length; i++) {
      if (i == selectedCartList.length - 1) {
        bookIdString += selectedCartList[i].book.id;
      } else {
        bookIdString += "${selectedCartList[i].book.id} ";
      }
    }
    try {
      for (var item in selectedCartList) {
        cartfoods.remove(item);
      }
      update();
      print(bookIdString);
      String token = (await SharedPrefs.getString("token"))!;
      var res = await http.post(Uri.parse("${base_url}user/cart"), headers: {
        "authorization": "Bearer $token",
      }, body: {
        "bookIdArray": bookIdString,
        "deleteItem": "0"
      });
      print("delete cart res : ${res.body}");

      // if(res.statusCode)
      if (res.statusCode == 201 && jsonDecode(res.body)["success"]) {
        selectedCartList.clear();
        showSnackBar(Get.context!, "Removed from cart successfully", false);
      } else {
        showSnackBar(Get.context!, "Something went wrong", true);
        for (var item in selectedCartList) {
          cartfoods.add(item);
        }
      }
      update();
    } catch (err) {
      print("Bookmark catch err : ${err}");
    }
    // genreLoader = false;
    update();
  }

  bool callForUpdateDays = false;
  int singleBookDays = 3;
  bool singlebookchange = false;

  Future<void> updateNoOfDays(String id, int i, bool singlebook) async {
    callForUpdateDays = true;
    update();
    print("delete api called");
    try {
      String token = (await SharedPrefs.getString("token"))!;
      var res =
          await http.put(Uri.parse("${base_url}user/cart/item/$id"), headers: {
        "authorization": "Bearer $token",
      }, body: {
        "noOfDays": noOfDaysController.text.trim()
      });

      print(res.statusCode);
      print(res.body);
      if (res.statusCode == 201 && jsonDecode(res.body)["success"]) {
        if (singlebook) {
          singleBookDays = int.parse(noOfDaysController.text.trim());
          update();
          print(singleBookDays);
          singlebookchange = true;
          Get.back();
        } else {
          cartfoods[i].noOfDays = int.parse(noOfDaysController.text.trim());
          Get.back();
        }
        showSnackBar(Get.context!, "Update days successfully", false);
      }
    } catch (err) {
      Get.back();
      showSnackBar(Get.context!, "Something went wrong", true);
      print("Bookmark catch err : ${err}");
    }
    callForUpdateDays = false;
    update();
  }

  void load() {
    loader = !loader;
    update();
  }

  bool getCartItemsLoader = false;

  getUserBookmarked() async {
    getCartItemsLoader = true;
    update();
    await callAndErrorHendling(
        errorOccurFunction: () {
          errorOccurUserBook = true;
          update();
        },
        callback: (data) {
          print("cart on call :: $data");
          variousFeesList.clear();
          List bookmarkList = data["msg"]["cartData"]["cart"]
              .map((e) => CartModel.fromMap(e))
              .toList();
          variousFees = Fees.fromMap(data["msg"]["subTotal"]);
          cartfoods = List<CartModel>.from(bookmarkList);
          // code toconvert Map<string, dynamic>from to List<Map<String, double>> in dart
          variousFees.toMap().forEach((key, value) {
            variousFeesList
                .add({camelToSentence(key): value != null ? value * 1.0 : 0.0});
          });
          print("cart books : ${variousFees.grandtotal}");
          print("fee books : ${variousFeesList.length}");
          update();
          // showSnackBar(Get.context!, "Added to cart successfully", true);
        },
        url: "${base_url}user/cart",
        method: "get",
        body: {});
    getCartItemsLoader = false;
    update();
  }

  String camelToSentence(String input) {
    StringBuffer sentence = new StringBuffer();
    for (int i = 0; i < input.length; i++) {
      if (i == 0) {
        sentence.write(input[i].toUpperCase());
      } else if (input[i].toUpperCase() == input[i]) {
        sentence.write(" ");
        sentence.write(input[i]);
      } else {
        sentence.write(input[i]);
      }
    }
    return sentence.toString();
  }

  double getTotalCharges() {
    return (variousFees.deliveryFees ?? 0) * 1.0 +
        (variousFees.serviceFees ?? 0) * 1.0 +
        (variousFees.internetHandlingFees ?? 0) * 1.0;
  }

  getUserBooks() async {
    load();
    await callAndErrorHendling(
        errorOccurFunction: () {
          errorOccurUserBook = true;
          update();
        },
        callback: (data) {
          // print("Data on call :: $data");
          List bookDataList = data["msg"]["booksAdded"]
              .map((e) => BookModel.fromMap(e))
              .toList();
          // print("user books : ${bookDataList[0]}");
          userBook = List<BookModel>.from(bookDataList);
          update();
        },
        url: "${base_url}user/get-books-uploadedby-single-user",
        method: "get",
        body: {});
    // print("BookModel : ${userBook[0]}");
    update();
    load();
  }

  Future callAndErrorHendling(
      {required Function callback,
      required Function errorOccurFunction,
      required String url,
      required String method,
      required Map body,
      bool? loader,
      String? error}) async {
    try {
      String token = (await SharedPrefs.getString("token")) ?? "";
      print("token : $token");
      print("Calling get book api");
      final response;
      if (method == "get") {
        response = await http.get(Uri.parse(url), headers: {
          "authorization": "Bearer $token",
        });
      } else if (method == "post") {
        response = await http.post(Uri.parse(url), body: body, headers: {
          "authorization": "Bearer $token",
        });
      } else {
        response = await http.put(Uri.parse(url), body: body, headers: {
          "authorization": "Bearer $token",
        });
      }
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        Map<String, dynamic> data = jsonDecode(response.body);
        // print(data);
        if (data["success"]) {
          // print(data);
          callback(data);
        } else {
          errorOccurFunction();
          Get.snackbar("Error", "Something went wrong");
        }
      } else {
        errorOccurFunction();
        // print(response.body);
        Get.snackbar("Error ", error ?? "Something went wrong");
      }
    } catch (e) {
      errorOccurFunction();
      Get.snackbar("Error", "Something went wrong");
      print("error catch  $url : ${e.toString()}");
    }
  }
}
