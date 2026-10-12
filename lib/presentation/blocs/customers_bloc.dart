import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';

class CustomersState extends Equatable {
  const CustomersState({this.customers = const [], this.loading = true});
  final List<Customer> customers;
  final bool loading;
  @override
  List<Object?> get props => [customers, loading];
}

abstract class CustomersEvent {}

class CustomersStarted extends CustomersEvent {}

class CustomerSaved extends CustomersEvent {
  CustomerSaved(this.customer);
  final Customer customer;
}

class CustomerDeleted extends CustomersEvent {
  CustomerDeleted(this.id);
  final String id;
}

class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  CustomersBloc(this._repo) : super(const CustomersState()) {
    on<CustomersStarted>((e, emit) => emit.forEach<List<Customer>>(_repo.watchCustomers(),
        onData: (l) => CustomersState(customers: l, loading: false)));
    on<CustomerSaved>((e, emit) => _repo.save(e.customer));
    on<CustomerDeleted>((e, emit) => _repo.delete(e.id));
    add(CustomersStarted());
  }
  final CustomerRepository _repo;
}
