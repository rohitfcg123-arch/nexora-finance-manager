import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'firebase_options.dart';

const green=Color(0xFF075C43), darkGreen=Color(0xFF063B2E), mint=Color(0xFFE6F5ED), bg=Color(0xFFF4F7F5), ink=Color(0xFF17231E);
final fmt=NumberFormat.currency(locale:'en_IN',symbol:'₹',decimalDigits:2);
final dateFmt=DateFormat('dd MMM yyyy');

Future<void> main() async {
 WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
 runApp(const NexoraApp());
}
class NexoraApp extends StatelessWidget {
 const NexoraApp({super.key});
 @override Widget build(BuildContext c)=>MaterialApp(title:'Nexora Finance Manager',debugShowCheckedModeBanner:false,theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:green),scaffoldBackgroundColor:bg,appBarTheme:const AppBarTheme(backgroundColor:bg,foregroundColor:Color(0xFF17231E),elevation:0)),home:const AuthGate());
}
class Txn {
 Txn({this.id='',required this.title,required this.amount,required this.date,required this.income,required this.category,this.ledger='Personal Expenses',this.note='',this.source='Manual'});
 String id,title,category,ledger,note,source; double amount; DateTime date; bool income;
 Map<String,dynamic> map()=>{'title':title,'amount':amount,'date':Timestamp.fromDate(date),'income':income,'category':category,'ledger':ledger,'note':note,'source':source,'updatedAt':FieldValue.serverTimestamp()};
 factory Txn.doc(DocumentSnapshot<Map<String,dynamic>> d){final m=d.data()??{}; final dt=m['date']; return Txn(id:d.id,title:(m['title']??'Transaction').toString(),amount:(m['amount'] as num? ?? 0).toDouble(),date:dt is Timestamp?dt.toDate():DateTime.now(),income:m['income']==true,category:(m['category']??'Other').toString(),ledger:(m['ledger']??'Personal Expenses').toString(),note:(m['note']??'').toString(),source:(m['source']??'Manual').toString());}
}
class AuthGate extends StatelessWidget {
 const AuthGate({super.key});
 @override Widget build(BuildContext c)=>StreamBuilder<User?>(stream:FirebaseAuth.instance.authStateChanges(),builder:(c,s){if(s.connectionState==ConnectionState.waiting)return const Scaffold(body:Center(child:CircularProgressIndicator()));return s.data==null?const LoginScreen():Home(user:s.data!);});
}
class LoginScreen extends StatefulWidget {const LoginScreen({super.key}); @override State<LoginScreen> createState()=>_LoginState();}
class _LoginState extends State<LoginScreen>{
 final email=TextEditingController(),pass=TextEditingController(),name=TextEditingController(); bool register=false,busy=false; String error='';
 Future<void> submit() async {setState(() { busy=true; error=''; }); try {if(register){final u=await FirebaseAuth.instance.createUserWithEmailAndPassword(email:email.text.trim(),password:pass.text); if(name.text.trim().isNotEmpty) await u.user?.updateDisplayName(name.text.trim()); await u.user?.sendEmailVerification(); await FirebaseFirestore.instance.collection('users').doc(u.user!.uid).set({'email':email.text.trim(),'displayName':name.text.trim(),'createdAt':FieldValue.serverTimestamp()},SetOptions(merge:true));}else{await FirebaseAuth.instance.signInWithEmailAndPassword(email:email.text.trim(),password:pass.text);}}on FirebaseAuthException catch(e){error=e.message??e.code;}catch(e){error='Firebase setup error. Check configuration and internet.';}if(mounted)setState(()=>busy=false);}
 Future<void> reset() async {if(email.text.trim().isEmpty){setState(()=>error='Enter your email first.');return;}try{await FirebaseAuth.instance.sendPasswordResetEmail(email:email.text.trim());setState(()=>error='Password reset email sent.');}catch(e){setState(()=>error='Could not send reset email.');}}
 @override Widget build(BuildContext c)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Container(height:72,width:72,alignment:Alignment.center,decoration:BoxDecoration(gradient:const LinearGradient(colors:[darkGreen,green]),borderRadius:BorderRadius.circular(22)),child:const Text('N',style:TextStyle(color:Colors.white,fontSize:40,fontWeight:FontWeight.w900)),),const SizedBox(height:20),const Text('Nexora Finance',style:TextStyle(fontSize:29,fontWeight:FontWeight.w900)),const Text('Your finances. Simplified. Smarter.'),const SizedBox(height:26),Text(register?'Create your account':'Welcome back',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),if(register)TextField(controller:name,decoration:const InputDecoration(labelText:'Name')),const SizedBox(height:10),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email')),const SizedBox(height:10),TextField(controller:pass,obscureText:true,decoration:const InputDecoration(labelText:'Password')),if(error.isNotEmpty)Padding(padding:const EdgeInsets.all(8),child:Text(error,style:const TextStyle(color:green))),const SizedBox(height:12),FilledButton(onPressed:busy?null:submit,style:FilledButton.styleFrom(backgroundColor:green,padding:const EdgeInsets.all(15)),child:Text(busy?'Please wait…':register?'Create account':'Sign in')),if(!register)TextButton(onPressed:reset,child:const Text('Forgot password?')),TextButton(onPressed:()=>setState(() { register=!register; error=''; }),child:Text(register?'Already registered? Sign in':'Create a new account'))]))))));
}
class Home extends StatefulWidget {const Home({super.key,required this.user}); final User user; @override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{
 int tab=0; String search='',filter='All';
 CollectionReference<Map<String,dynamic>> get ref=>FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('transactions');
 final categories=['Food & Dining','Shopping','Travel','Utilities','Salary / Income','Bank Charges','Transfer','Health','Other'];
 final ledgers=['Personal Expenses','Office Expenses','Business Expenses','Bank Account','Income Account'];
 String autoCat(String n,bool income){if(income)return 'Salary / Income';final s=n.toLowerCase();if(RegExp(r'amazon|flipkart|myntra').hasMatch(s))return 'Shopping';if(RegExp(r'swiggy|zomato|restaurant|cafe|food').hasMatch(s))return 'Food & Dining';if(RegExp(r'uber|ola|irctc|petrol|fuel|flight').hasMatch(s))return 'Travel';if(RegExp(r'electricity|broadband|mobile bill|water bill').hasMatch(s))return 'Utilities';if(RegExp(r'bank charge|atm fee').hasMatch(s))return 'Bank Charges';return 'Other';}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Row(children:[Container(width:38,height:38,alignment:Alignment.center,decoration:BoxDecoration(color:green,borderRadius:BorderRadius.circular(12)),child:const Text('N',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:22)),),const SizedBox(width:10),const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Nexora',style:TextStyle(fontWeight:FontWeight.w900)),Text('FINANCE MANAGER',style:TextStyle(fontSize:9,letterSpacing:1.1))])]),actions:[IconButton(onPressed:importFile,icon:const Icon(Icons.upload_file)),IconButton(onPressed:()=>FirebaseAuth.instance.signOut(),icon:const Icon(Icons.logout))]),body:IndexedStack(index:tab,children:[dashboard(),transactions(),reports(),settings()]),floatingActionButton:tab<2?FloatingActionButton.extended(backgroundColor:green,foregroundColor:Colors.white,onPressed:()=>edit(),icon:const Icon(Icons.add),label:const Text('Add transaction')):null,bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),backgroundColor:Colors.white,indicatorColor:mint,destinations:const[NavigationDestination(icon:Icon(Icons.home_outlined),label:'Home'),NavigationDestination(icon:Icon(Icons.receipt_long_outlined),label:'Transactions'),NavigationDestination(icon:Icon(Icons.pie_chart_outline),label:'Reports'),NavigationDestination(icon:Icon(Icons.settings_outlined),label:'Settings')]));
 Widget dashboard()=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
  stream:ref.orderBy('date',descending:true).limit(300).snapshots(),
  builder:(c,s){
   final list=(s.data?.docs??[]).map(Txn.doc).toList();
   final inc=list.where((t)=>t.income).fold<double>(0,(a,t)=>a+t.amount);
   final exp=list.where((t)=>!t.income).fold<double>(0,(a,t)=>a+t.amount);
   return ListView(
    padding:const EdgeInsets.all(16),
    children:[
     Container(
      padding:const EdgeInsets.all(20),
      decoration:BoxDecoration(gradient:const LinearGradient(colors:[darkGreen,green]),borderRadius:BorderRadius.circular(24)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       const Text('TOTAL CASH FLOW',style:TextStyle(color:Colors.white70,letterSpacing:1)),
       const SizedBox(height:10),
       Text(fmt.format(inc-exp),style:const TextStyle(color:Colors.white,fontSize:30,fontWeight:FontWeight.w900)),
       const SizedBox(height:18),
       Row(children:[
        Expanded(child:Text('Income\n${fmt.format(inc)}',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700))),
        Expanded(child:Text('Expenses\n${fmt.format(exp)}',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700))),
       ]),
      ]),
     ),
     const SizedBox(height:14),
     Row(children:[
      Expanded(child:quick('Manual entry',Icons.add_circle_outline,()=>edit())),
      const SizedBox(width:8),
      Expanded(child:quick('Import statement',Icons.upload_file,importFile)),
      const SizedBox(width:8),
      Expanded(child:quick('Reports',Icons.pie_chart_outline,()=>setState(()=>tab=2))),
     ]),
     const SizedBox(height:20),
     title('Recent transactions','View all',()=>setState(()=>tab=1)),
     if(s.hasError) const Text('Firestore error: check that rules are published.')
     else if(list.isEmpty) const Text('No transactions yet. Add a transaction or import a statement.')
     else ...list.take(8).map((t)=>tile(t)),
    ],
   );
  },
 );
 Widget quick(String label,IconData icon,VoidCallback onTap)=>Expanded(child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(15),child:Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:const Color(0xFFE1E9E4)),borderRadius:BorderRadius.circular(15)),child:Column(children:[Icon(icon,color:green,size:27),const SizedBox(height:6),Text(label,textAlign:TextAlign.center,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w700))]))));
 Widget title(String t,String action,VoidCallback cb)=>Row(children:[Expanded(child:Text(t,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900))),TextButton(onPressed:cb,child:Text(action))]);
 Widget tile(Txn t)=>Card(color:Colors.white,elevation:0,child:ListTile(onTap:()=>edit(t),leading:CircleAvatar(backgroundColor:t.income?mint:const Color(0xFFFFF1E7),child:Icon(t.income?Icons.south_west:Icons.north_east,color:t.income?green:Colors.deepOrange)),title:Text(t.title,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(t.category+' • '+DateFormat('dd MMM').format(t.date)+' • '+t.source,style:const TextStyle(fontSize:10)),trailing:Text((t.income?'+':'−')+fmt.format(t.amount),style:TextStyle(fontWeight:FontWeight.w800,color:t.income?green:ink))));
 Widget transactions()=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:ref.orderBy('date',descending:true).limit(500).snapshots(),builder:(c,s){final list=(s.data?.docs??[]).map(Txn.doc).where((t)=>(filter=='All'||(filter=='Income'?t.income:!t.income))&&(t.title+' '+t.category+' '+t.note).toLowerCase().contains(search.toLowerCase())).toList();return ListView(padding:const EdgeInsets.all(16),children:[const Text('Transactions',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:10),TextField(onChanged:(v)=>setState(()=>search=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search transactions')),Wrap(spacing:8,children:['All','Expense','Income'].map((v)=>ChoiceChip(label:Text(v),selected:filter==v,onSelected:(_)=>setState(()=>filter=v))).toList()),...list.map(tile)]);});
 Widget reports()=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:ref.orderBy('date',descending:true).limit(500).snapshots(),builder:(c,s){final list=(s.data?.docs??[]).map(Txn.doc).toList();final inc=list.where((t)=>t.income).fold<double>(0,(a,t)=>a+t.amount);final exp=list.where((t)=>!t.income).fold<double>(0,(a,t)=>a+t.amount);final totals=<String,double>{};for(final t in list.where((t)=>!t.income)){totals[t.category]=(totals[t.category]??0)+t.amount;}final entries=totals.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));return ListView(padding:const EdgeInsets.all(16),children:[const Text('Reports & analytics',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:12),Text('Income: '+fmt.format(inc)),Text('Expenses: '+fmt.format(exp)),const SizedBox(height:18),const Text('Expenses by category',style:TextStyle(fontWeight:FontWeight.w800)),...entries.map((e)=>ListTile(title:Text(e.key),subtitle:LinearProgressIndicator(value:exp==0?0:e.value/exp,color:green,backgroundColor:mint),trailing:Text(fmt.format(e.value))))]);});
 Widget settings()=>ListView(padding:const EdgeInsets.all(16),children:[const Text('Settings',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),ListTile(leading:const Icon(Icons.person),title:Text(widget.user.email??''),subtitle:const Text('Signed in with Firebase')),ListTile(leading:const Icon(Icons.upload_file),title:const Text('Import statement'),subtitle:const Text('PDF, CSV, XLS, XLSX'),onTap:importFile),ListTile(leading:const Icon(Icons.logout),title:const Text('Sign out'),onTap:()=>FirebaseAuth.instance.signOut()),const Text('Cloud sync is active for this signed-in user. PDF extraction is best-effort; always verify imported amounts.')]);
 Future<void> edit([Txn? old])async{final titleC=TextEditingController(text:old?.title??''),amountC=TextEditingController(text:old==null?'':old.amount.toString()),noteC=TextEditingController(text:old?.note??'');bool income=old?.income??false;String cat=old?.category??'Other',ledger=old?.ledger??'Personal Expenses';DateTime date=old?.date??DateTime.now();final cats={...categories,cat}.toList(),accounts={...ledgers,ledger}.toList();await showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.white,builder:(ctx)=>StatefulBuilder(builder:(ctx,ss)=>Padding(padding:EdgeInsets.fromLTRB(18,18,18,MediaQuery.of(ctx).viewInsets.bottom+18),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(old==null?'Add transaction':'Edit transaction',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:12),SegmentedButton<bool>(segments:const[ButtonSegment(value:false,label:Text('Expense')),ButtonSegment(value:true,label:Text('Income'))],selected:{income},onSelectionChanged:(v)=>ss(()=>income=v.first)),const SizedBox(height:10),TextField(controller:amountC,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Amount (₹)')),const SizedBox(height:10),TextField(controller:titleC,decoration:const InputDecoration(labelText:'Merchant / description')),ListTile(contentPadding:EdgeInsets.zero,title:const Text('Date'),subtitle:Text(dateFmt.format(date)),trailing:const Icon(Icons.calendar_month),onTap:()async{final d=await showDatePicker(context:ctx,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime.now().add(const Duration(days:365)));if(d!=null)ss(()=>date=d);}),DropdownButtonFormField<String>(value:cat,decoration:const InputDecoration(labelText:'Category'),items:cats.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>ss(()=>cat=v??cat)),const SizedBox(height:10),DropdownButtonFormField<String>(value:ledger,decoration:const InputDecoration(labelText:'Account / ledger'),items:accounts.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>ss(()=>ledger=v??ledger)),const SizedBox(height:10),TextField(controller:noteC,decoration:const InputDecoration(labelText:'Note (optional)')),const SizedBox(height:14),SizedBox(width:double.infinity,child:FilledButton(onPressed:()async{final amount=double.tryParse(amountC.text.replaceAll(',',''));if(amount==null||amount<=0||titleC.text.trim().isEmpty){snack('Enter valid amount and description.');return;}final tx=Txn(id:old?.id??DateTime.now().microsecondsSinceEpoch.toString(),title:titleC.text.trim(),amount:amount,date:date,income:income,category:cat,ledger:ledger,note:noteC.text.trim(),source:old?.source??'Manual');try{await ref.doc(tx.id).set(tx.map(),SetOptions(merge:true));if(ctx.mounted)Navigator.pop(ctx);snack('Saved to Firebase.');}catch(e){snack('Save failed. Check Firestore rules and internet.');}},child:const Text('Save transaction'))),if(old!=null)TextButton(onPressed:()async{await ref.doc(old.id).delete();if(ctx.mounted)Navigator.pop(ctx);},child:const Text('Delete transaction'))])))));}

 Future<void> importFile()async{final picked=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['csv','xls','xlsx','pdf'],withData:true);if(picked==null||picked.files.isEmpty)return;final file=picked.files.single;final bytes=file.bytes;if(bytes==null){snack('Could not read file.');return;}try{List<List<dynamic>> rows;final ext=(file.extension??'').toLowerCase();if(ext=='csv'){rows=const CsvToListConverter(shouldParseNumbers:false,allowInvalid:true).convert(utf8.decode(bytes,allowMalformed:true));}else if(ext=='xls'||ext=='xlsx'){final book=xls.Excel.decodeBytes(bytes);if(book.tables.isEmpty)throw Exception('No worksheet found.');rows=book.tables.values.first!.rows.map((r)=>r.map((c)=>c?.value?.toString()??'').toList()).toList();}else if(ext=='pdf'){final doc=PdfDocument(inputBytes:bytes);final extractor=PdfTextExtractor(doc);final text=extractor.extractText(layoutText:true);rows=parsePdf(text);doc.dispose();}else{throw Exception('Unsupported file');}final parsed=parseRows(rows);if(parsed.isEmpty)throw Exception('No transactions detected. Use columns Date, Narration, Debit/Credit or Amount.');if(!mounted)return;final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text('Preview import: '+parsed.length.toString()+' rows'),content:SizedBox(width:300,height:350,child:ListView(children:parsed.take(35).map((t)=>ListTile(dense:true,title:Text(t.title),subtitle:Text(dateFmt.format(t.date)+' • '+t.category),trailing:Text(fmt.format(t.amount)))).toList())),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Import'))]));if(yes!=true)return;int added=0;for(var i=0;i<parsed.length;i+=400){final batch=FirebaseFirestore.instance.batch();for(final t in parsed.skip(i).take(400)){t.source='Statement: '+file.name;batch.set(ref.doc(t.id),t.map());added++;}await batch.commit();}snack('Imported '+added.toString()+' transactions. Please review the categories.');}catch(e){snack('Import failed: '+e.toString().replaceFirst('Exception: ',''));}}
 List<List<dynamic>> parsePdf(String text){
  // ICICI statements place the merchant, transaction amount and UPI reference
  // on separate visual lines. Preserve layout spacing and parse each numbered
  // transaction row instead of expecting date/narration/amount on one line.
  final rows=<List<dynamic>>[['Date','Narration','Debit','Credit']];
  final iciciRow=RegExp(r'^\s*(\d{1,4})\s+(\d{2}\.\d{2}\.\d{4})\s+(.*)$');
  final money=RegExp(r'\d[\d,]*\.\d{2}');
  final skip=<String>[
   'transaction remarks','withdrawal amount','deposit amount','balance (inr)',
   'transaction date','s no.','www.icici.bank.in','dial your bank',
   'please call from your registered mobile number','never share your otp',
   'statement of transactions','your base branch:','ground floor, industry house',
   'camac street','west bengal - india','banjemari koliya','amount (inr)'
  ];
  bool inTable=false;
  final narrationLines=<String>[];
  var recognized=0;
  for(final line in text.split(RegExp(r'[\r\n]+'))){
   if(line.contains('S No.')){inTable=true;narrationLines.clear();continue;}
   if(!inTable)continue;
   final lower=line.toLowerCase();
   if(skip.any((s)=>lower.contains(s)))continue;
   final match=iciciRow.firstMatch(line);
   if(match!=null){
    final values=money.allMatches(match.group(3)!).toList();
    if(values.length>=2){
     final transactionAmount=values[values.length-2];
     final amount=double.tryParse(transactionAmount.group(0)!.replaceAll(',',''))??0;
     final absolutePosition=match.start(3)+transactionAmount.start;
     // In this ICICI layout, withdrawal amounts start left of the deposit
     // column; deposits are consistently positioned farther to the right.
     final isDeposit=absolutePosition>=116;
     final candidates=narrationLines
      .map((s)=>s.trim())
      .where((s)=>s.isNotEmpty && !RegExp(r'^\d+$').hasMatch(s))
      .where((s)=>!skip.any((x)=>s.toLowerCase().contains(x)))
      .toList();
     final merchant=candidates.reversed.firstWhere(
      (s)=>!s.toUpperCase().startsWith('UPI/'),
      orElse:()=>candidates.isEmpty?'':candidates.last,
     );
     if(amount>0 && merchant.isNotEmpty){
      rows.add([match.group(2),merchant,isDeposit?'':amount.toStringAsFixed(2),isDeposit?amount.toStringAsFixed(2):'']);
      recognized++;
     }
    }
    narrationLines.clear();
    continue;
   }
   if(line.trim().isNotEmpty && !RegExp(r'^\d+$').hasMatch(line.trim())){
    narrationLines.add(line);
   }
  }
  if(recognized>=3)return rows;
  // Keep a conservative fallback for other text-based PDFs.
  final fallback=<List<dynamic>>[['Date','Narration','Amount']];
  final date=RegExp(r'^(\d{1,2}[./-]\d{1,2}[./-]\d{2,4}|\d{4}-\d{2}-\d{2})\s+(.+)$');
  final amt=RegExp(r'(-?\d[\d,]*\.\d{2})(?:\s*(CR|DR))?\s*$',caseSensitive:false);
  for(final line in text.split(RegExp(r'[\r\n]+'))){
   final d=date.firstMatch(line.trim());if(d==null)continue;
   final a=amt.firstMatch(d.group(2)!);if(a==null)continue;
   final narr=d.group(2)!.substring(0,a.start).trim();if(narr.isEmpty)continue;
   fallback.add([d.group(1),narr,(a.group(1)??'')+(a.group(2)==null?'':' '+a.group(2)! )]);
  }
  return fallback;
 }
 List<Txn> parseRows(List<List<dynamic>> rows){if(rows.length<2)return[];String norm(dynamic v)=>v.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'),'');final h=rows.first.map(norm).toList();int ix(List<String> names)=>h.indexWhere((x)=>names.any((n)=>x.contains(n)));final di=ix(['date','transactiondate','valuedate']),ni=ix(['narration','description','particulars','details','remarks','merchant','payee']),de=ix(['debit','withdrawal','paidout']),cr=ix(['credit','deposit','paidin']),am=ix(['amount','transactionamount']);if(di<0||ni<0||(de<0&&cr<0&&am<0))throw Exception('Could not identify Date, Narration and amount columns.');String cell(List<dynamic> r,int i)=>i>=0&&i<r.length?r[i].toString().trim():'';double val(String s)=>double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'),''))??0;DateTime dt(String s){for(final f in ['dd/MM/yyyy','dd-MM-yyyy','dd.MM.yyyy','d/M/yy','yyyy-MM-dd','dd MMM yyyy']){try{return DateFormat(f).parseStrict(s);}catch(_){}}return DateTime.now();}final out=<Txn>[];for(final r in rows.skip(1)){final title=cell(r,ni);if(title.isEmpty)continue;final debit=val(cell(r,de)),credit=val(cell(r,cr));final raw=cell(r,am);final income=credit>0?true:debit>0?false:(raw.toLowerCase().contains('cr')||raw.startsWith('+'));final amount=credit>0?credit:debit>0?debit:val(raw);if(amount<=0)continue;out.add(Txn(id:DateTime.now().microsecondsSinceEpoch.toString()+out.length.toString(),title:title,amount:amount,date:dt(cell(r,di)),income:income,category:autoCat(title,income),ledger:income?'Income Account':'Personal Expenses',source:'Statement import'));}return out;}
 String autoCatUnused(String n,bool income){if(income)return'Salary / Income';final s=n.toLowerCase();if(RegExp(r'amazon|flipkart|myntra').hasMatch(s))return'Shopping';if(RegExp(r'swiggy|zomato|restaurant|cafe|food').hasMatch(s))return'Food & Dining';if(RegExp(r'uber|ola|irctc|petrol|fuel|flight').hasMatch(s))return'Travel';if(RegExp(r'electricity|broadband|mobile bill|water bill').hasMatch(s))return'Utilities';if(RegExp(r'bank charge|atm fee').hasMatch(s))return'Bank Charges';return'Other';}
 void snack(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
}
